/*
  # Add Pool Management Tables and Policies

  1. New Tables
    - companions
    - reservations
    - reservation_companions
    - entries

  2. Security
    - Enable RLS on all tables
    - Add policies for data access (with existence checks)
    
  3. Performance
    - Add indexes for common queries
*/

-- Companions table
CREATE TABLE IF NOT EXISTS companions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  name text NOT NULL,
  dni text NOT NULL,
  age integer NOT NULL CHECK (age >= 0 AND age <= 120),
  phone text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz DEFAULT now(),
  UNIQUE(dni, user_id)
);

-- Reservations table
CREATE TABLE IF NOT EXISTS reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  date date NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  created_at timestamptz DEFAULT now()
);

-- Reservation companions junction table
CREATE TABLE IF NOT EXISTS reservation_companions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id uuid REFERENCES reservations(id) ON DELETE CASCADE,
  companion_id uuid REFERENCES companions(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(reservation_id, companion_id)
);

-- Entries table for tracking pool access
CREATE TABLE IF NOT EXISTS entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  companion_id uuid REFERENCES companions(id) ON DELETE CASCADE,
  entry_date date NOT NULL DEFAULT CURRENT_DATE,
  entry_time time NOT NULL DEFAULT CURRENT_TIME,
  type text NOT NULL CHECK (type IN ('affiliate', 'companion')),
  price numeric(10,2) NOT NULL DEFAULT 0,
  discount integer NOT NULL DEFAULT 0 CHECK (discount >= 0 AND discount <= 100),
  created_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE companions ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservation_companions ENABLE ROW LEVEL SECURITY;
ALTER TABLE entries ENABLE ROW LEVEL SECURITY;

-- Create policies with existence checks
DO $$ 
BEGIN
  -- Companions policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own companions'
  ) THEN
    CREATE POLICY "Users can insert own companions" ON companions
      FOR INSERT WITH CHECK (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own companions'
  ) THEN
    CREATE POLICY "Users can update own companions" ON companions
      FOR UPDATE USING (user_id = auth.uid());
  END IF;

  -- Reservations policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can read own reservations'
  ) THEN
    CREATE POLICY "Users can read own reservations" ON reservations
      FOR SELECT USING (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own reservations'
  ) THEN
    CREATE POLICY "Users can insert own reservations" ON reservations
      FOR INSERT WITH CHECK (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can update own reservations'
  ) THEN
    CREATE POLICY "Users can update own reservations" ON reservations
      FOR UPDATE USING (user_id = auth.uid());
  END IF;

  -- Reservation companions policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can read own reservation companions'
  ) THEN
    CREATE POLICY "Users can read own reservation companions" ON reservation_companions
      FOR SELECT USING (
        EXISTS (
          SELECT 1 FROM reservations r
          WHERE r.id = reservation_id
          AND r.user_id = auth.uid()
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can insert own reservation companions'
  ) THEN
    CREATE POLICY "Users can insert own reservation companions" ON reservation_companions
      FOR INSERT WITH CHECK (
        EXISTS (
          SELECT 1 FROM reservations r
          WHERE r.id = reservation_id
          AND r.user_id = auth.uid()
        )
      );
  END IF;

  -- Entries policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Users can read own entries'
  ) THEN
    CREATE POLICY "Users can read own entries" ON entries
      FOR SELECT USING (user_id = auth.uid());
  END IF;
END $$;

-- Create indexes for better performance
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_companions_user_id') THEN
    CREATE INDEX idx_companions_user_id ON companions(user_id);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_companions_dni') THEN
    CREATE INDEX idx_companions_dni ON companions(dni);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_reservations_user_id_date') THEN
    CREATE INDEX idx_reservations_user_id_date ON reservations(user_id, date);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_entries_user_id_date') THEN
    CREATE INDEX idx_entries_user_id_date ON entries(user_id, entry_date);
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_entries_companion_id_date') THEN
    CREATE INDEX idx_entries_companion_id_date ON entries(companion_id, entry_date);
  END IF;
END $$;

-- Create functions for common operations
CREATE OR REPLACE FUNCTION get_daily_entries(check_date date)
RETURNS TABLE (
  affiliate_count bigint,
  companion_count bigint,
  total_count bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*) FILTER (WHERE type = 'affiliate') as affiliate_count,
    COUNT(*) FILTER (WHERE type = 'companion') as companion_count,
    COUNT(*) as total_count
  FROM entries
  WHERE entry_date = check_date;
END;
$$ LANGUAGE plpgsql;