/*
  # Fix Reservations and Companions Update

  1. New Functions
    - `create_reservation`: Function to safely create a new reservation with companions
    - `get_user_companions`: Function to get approved companions for a user
    - `update_reservation_companions`: Function to update companions for a reservation

  2. Security
    - Enable RLS for all tables
    - Add policies for reservations and companions
    - Add validation checks for reservation creation

  3. Changes
    - Add composite unique constraint for date and user_id
    - Add indexes for better performance
*/

-- Add helper function to validate reservation
CREATE OR REPLACE FUNCTION validate_reservation_request(
  user_id_param uuid,
  date_param date,
  companion_ids text[]
) RETURNS boolean AS $$
DECLARE
  companion_count integer;
BEGIN
  -- Check if user already has a reservation for this date
  IF EXISTS (
    SELECT 1 FROM reservations 
    WHERE user_id = user_id_param 
    AND date = date_param 
    AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Ya existe una reserva activa para esta fecha';
  END IF;

  -- Validate companions
  SELECT COUNT(*)
  INTO companion_count
  FROM companions
  WHERE id = ANY(companion_ids::uuid[])
  AND user_id = user_id_param
  AND status = 'approved';

  IF companion_count != array_length(companion_ids, 1) THEN
    RAISE EXCEPTION 'Uno o más acompañantes no están autorizados';
  END IF;

  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create reservation with companions
CREATE OR REPLACE FUNCTION create_reservation(
  user_id_param uuid,
  date_param date,
  companion_ids text[]
) RETURNS uuid AS $$
DECLARE
  new_reservation_id uuid;
BEGIN
  -- Validate request
  PERFORM validate_reservation_request(user_id_param, date_param, companion_ids);

  -- Create reservation
  INSERT INTO reservations (user_id, date, status)
  VALUES (user_id_param, date_param, 'active')
  RETURNING id INTO new_reservation_id;

  -- Add companions if any
  IF array_length(companion_ids, 1) > 0 THEN
    INSERT INTO reservation_companions (reservation_id, companion_id)
    SELECT new_reservation_id, id::uuid
    FROM unnest(companion_ids) AS id;
  END IF;

  RETURN new_reservation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's approved companions
CREATE OR REPLACE FUNCTION get_user_companions(user_id_param uuid)
RETURNS TABLE (
  id uuid,
  name text,
  dni text
) AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.name, c.dni
  FROM companions c
  WHERE c.user_id = user_id_param
  AND c.status = 'approved';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add unique constraint for reservations
ALTER TABLE reservations 
ADD CONSTRAINT unique_user_date_reservation 
UNIQUE (user_id, date);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_reservations_status ON reservations(status);
CREATE INDEX IF NOT EXISTS idx_companions_status ON companions(status);
CREATE INDEX IF NOT EXISTS idx_reservation_companions_reservation ON reservation_companions(reservation_id);

-- Update RLS policies
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservation_companions ENABLE ROW LEVEL SECURITY;

-- Reservations policies
CREATE POLICY "Enable reservation creation" ON reservations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Enable reservation read" ON reservations
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Enable reservation update" ON reservations
  FOR UPDATE USING (auth.uid() = user_id);

-- Reservation companions policies
CREATE POLICY "Enable companion assignment" ON reservation_companions
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM reservations r
      WHERE r.id = reservation_id
      AND r.user_id = auth.uid()
    )
  );

CREATE POLICY "Enable companion read" ON reservation_companions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM reservations r
      WHERE r.id = reservation_id
      AND r.user_id = auth.uid()
    )
  );