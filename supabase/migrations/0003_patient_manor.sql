/*
  # Schema Updates for FADIUNC y El Olmo

  1. New Features
    - Add performance indexes
    - Add helper functions for statistics and availability checking
    - Add constraints for data integrity
    - Add automatic status update trigger

  2. Security
    - Update RLS policies where needed
*/

-- Add missing indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_dni ON users(dni);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_companions_status ON companions(status);
CREATE INDEX IF NOT EXISTS idx_reservations_date ON reservations(date);
CREATE INDEX IF NOT EXISTS idx_entries_entry_date ON entries(entry_date);

-- Add helper functions
CREATE OR REPLACE FUNCTION get_daily_stats(check_date date)
RETURNS TABLE (
  total_entries bigint,
  affiliate_entries bigint,
  companion_entries bigint,
  total_reservations bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) FILTER (WHERE e.entry_date = check_date) as total_entries,
    COUNT(*) FILTER (WHERE e.entry_date = check_date AND e.type = 'affiliate') as affiliate_entries,
    COUNT(*) FILTER (WHERE e.entry_date = check_date AND e.type = 'companion') as companion_entries,
    COUNT(DISTINCT r.id) FILTER (WHERE r.date = check_date AND r.status = 'active') as total_reservations
  FROM entries e
  LEFT JOIN reservations r ON r.date = e.entry_date;
END;
$$ LANGUAGE plpgsql;

-- Add function to check reservation availability
CREATE OR REPLACE FUNCTION check_reservation_availability(
  check_date date,
  is_affiliate boolean
)
RETURNS boolean AS $$
DECLARE
  current_count integer;
  max_limit integer;
BEGIN
  SELECT COUNT(*)
  INTO current_count
  FROM reservations r
  WHERE r.date = check_date
  AND r.status = 'active';

  max_limit := CASE
    WHEN is_affiliate THEN 
      CASE 
        WHEN EXTRACT(DOW FROM check_date) IN (0, 6) THEN 140
        ELSE 80
      END
    ELSE
      CASE 
        WHEN EXTRACT(DOW FROM check_date) IN (0, 6) THEN 80
        ELSE 60
      END
  END;

  RETURN current_count < max_limit;
END;
$$ LANGUAGE plpgsql;

-- Add constraints (using DO block to handle existing constraints)
DO $$ 
BEGIN
  BEGIN
    ALTER TABLE users 
      ADD CONSTRAINT users_status_check 
      CHECK (status IN ('pending', 'approved', 'rejected'));
  EXCEPTION
    WHEN duplicate_object THEN NULL;
  END;

  BEGIN
    ALTER TABLE companions 
      ADD CONSTRAINT companions_status_check 
      CHECK (status IN ('pending', 'approved', 'rejected'));
  EXCEPTION
    WHEN duplicate_object THEN NULL;
  END;

  BEGIN
    ALTER TABLE reservations 
      ADD CONSTRAINT reservations_status_check 
      CHECK (status IN ('active', 'completed', 'cancelled'));
  EXCEPTION
    WHEN duplicate_object THEN NULL;
  END;
END $$;

-- Update RLS policies (drop and recreate only new ones)
DO $$ 
BEGIN
  -- Companions policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'companions' 
    AND policyname = 'Users can insert own companions'
  ) THEN
    CREATE POLICY "Users can insert own companions" ON companions
      FOR INSERT WITH CHECK (user_id = auth.uid());
  END IF;

  -- Reservations policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'reservations' 
    AND policyname = 'Users can update own reservations'
  ) THEN
    CREATE POLICY "Users can update own reservations" ON reservations
      FOR UPDATE USING (user_id = auth.uid());
  END IF;

  -- Entries policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'entries' 
    AND policyname = 'Users can read own entries'
  ) THEN
    CREATE POLICY "Users can read own entries" ON entries
      FOR SELECT USING (user_id = auth.uid());
  END IF;
END $$;

-- Add triggers for automatic status updates
CREATE OR REPLACE FUNCTION update_reservation_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.entry_date > CURRENT_DATE THEN
    UPDATE reservations
    SET status = 'completed'
    WHERE id = NEW.reservation_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Only create trigger if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'entry_after_insert'
  ) THEN
    CREATE TRIGGER entry_after_insert
      AFTER INSERT ON entries
      FOR EACH ROW
      EXECUTE FUNCTION update_reservation_status();
  END IF;
END $$;