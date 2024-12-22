/*
  # Fix Admin Authentication

  1. Changes
    - Add admin auth functions
    - Update RLS policies
    - Add admin management functions

  2. Security
    - Secure admin checks
    - Protected admin operations
*/

-- Add admin auth functions
CREATE OR REPLACE FUNCTION check_admin_auth()
RETURNS boolean AS $$
BEGIN
  -- Get current user's email from auth.jwt()
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND is_admin = true
    AND status = 'approved'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add admin management functions
CREATE OR REPLACE FUNCTION admin_approve_user(user_id_param uuid)
RETURNS void AS $$
BEGIN
  IF NOT check_admin_auth() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  UPDATE users
  SET status = 'approved'
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION admin_reject_user(user_id_param uuid)
RETURNS void AS $$
BEGIN
  IF NOT check_admin_auth() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  UPDATE users
  SET status = 'rejected'
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update RLS policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  -- Drop existing policies
  DROP POLICY IF EXISTS "Admin can read all" ON users;
  DROP POLICY IF EXISTS "Admin can update all" ON users;
  DROP POLICY IF EXISTS "Users can read own data" ON users;

  -- Create new policies
  CREATE POLICY "Admin full access" ON users
    FOR ALL USING (check_admin_auth());

  CREATE POLICY "Users read own data" ON users
    FOR SELECT USING (auth.uid() = id);

  CREATE POLICY "Users update own data" ON users
    FOR UPDATE USING (auth.uid() = id);
END $$;