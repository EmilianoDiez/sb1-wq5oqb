/*
  # Additional Database Functions and Improvements

  1. New Functions:
    - get_user_stats: Get statistics for a specific user
    - get_companion_stats: Get statistics for companions
    - validate_reservation: Validate reservation constraints

  2. Additional Indexes:
    - Composite indexes for common queries
    - Partial indexes for active records
*/

-- Add composite indexes for common queries
CREATE INDEX IF NOT EXISTS idx_reservations_user_date ON reservations(user_id, date);
CREATE INDEX IF NOT EXISTS idx_entries_user_type ON entries(user_id, type);
CREATE INDEX IF NOT EXISTS idx_companions_user_status ON companions(user_id, status);

-- Add partial indexes for active records
CREATE INDEX IF NOT EXISTS idx_active_reservations ON reservations(date) 
WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_approved_companions ON companions(user_id) 
WHERE status = 'approved';

-- Function to get user statistics
CREATE OR REPLACE FUNCTION get_user_stats(user_id_param uuid)
RETURNS TABLE (
  total_reservations bigint,
  active_reservations bigint,
  total_entries bigint,
  companion_count bigint
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(DISTINCT r.id) as total_reservations,
    COUNT(DISTINCT CASE WHEN r.status = 'active' THEN r.id END) as active_reservations,
    COUNT(DISTINCT e.id) as total_entries,
    COUNT(DISTINCT c.id) as companion_count
  FROM users u
  LEFT JOIN reservations r ON r.user_id = u.id
  LEFT JOIN entries e ON e.user_id = u.id
  LEFT JOIN companions c ON c.user_id = u.id
  WHERE u.id = user_id_param;
END;
$$ LANGUAGE plpgsql;

-- Function to get companion statistics
CREATE OR REPLACE FUNCTION get_companion_stats(user_id_param uuid)
RETURNS TABLE (
  companion_id uuid,
  companion_name text,
  total_entries bigint,
  last_entry timestamptz
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id,
    c.name,
    COUNT(e.id) as total_entries,
    MAX(e.created_at) as last_entry
  FROM companions c
  LEFT JOIN entries e ON e.companion_id = c.id
  WHERE c.user_id = user_id_param
  GROUP BY c.id, c.name;
END;
$$ LANGUAGE plpgsql;

-- Function to validate reservation constraints
CREATE OR REPLACE FUNCTION validate_reservation(
  user_id_param uuid,
  date_param date,
  companion_count integer
) RETURNS TABLE (
  is_valid boolean,
  error_message text
) AS $$
DECLARE
  existing_count integer;
  max_companions integer := 3;
  max_daily_reservations integer := 1;
BEGIN
  -- Check for existing reservations on the same date
  SELECT COUNT(*)
  INTO existing_count
  FROM reservations
  WHERE user_id = user_id_param
  AND date = date_param
  AND status = 'active';

  IF existing_count >= max_daily_reservations THEN
    RETURN QUERY SELECT false, 'Ya tenés una reserva activa para esta fecha';
    RETURN;
  END IF;

  -- Validate companion count
  IF companion_count > max_companions THEN
    RETURN QUERY SELECT false, 'Máximo 3 acompañantes permitidos';
    RETURN;
  END IF;

  -- If all validations pass
  RETURN QUERY SELECT true, null::text;
END;
$$ LANGUAGE plpgsql;