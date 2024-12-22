/*
  # Fix Admin Functions

  1. New Functions
    - Add companion approval functions
    - Add companion rejection functions

  2. Security
    - Secure admin operations
    - Add proper error handling
*/

-- Add companion management functions
CREATE OR REPLACE FUNCTION admin_approve_companion(companion_id_param uuid)
RETURNS void AS $$
BEGIN
  IF NOT check_admin_auth() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  UPDATE companions
  SET status = 'approved'
  WHERE id = companion_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION admin_reject_companion(companion_id_param uuid)
RETURNS void AS $$
BEGIN
  IF NOT check_admin_auth() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  UPDATE companions
  SET status = 'rejected'
  WHERE id = companion_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update RLS policies for companions
DO $$ 
BEGIN
  -- Drop existing policies
  DROP POLICY IF EXISTS "Admin can update companions" ON companions;
  DROP POLICY IF EXISTS "Users can read own companions" ON companions;

  -- Create new policies
  CREATE POLICY "Admin full access" ON companions
    FOR ALL USING (check_admin_auth());

  CREATE POLICY "Users read own companions" ON companions
    FOR SELECT USING (user_id = auth.uid());

  CREATE POLICY "Users update own companions" ON companions
    FOR UPDATE USING (user_id = auth.uid());
END $$;