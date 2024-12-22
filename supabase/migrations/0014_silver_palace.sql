/*
  # Fix Admin Authentication

  1. Functions
    - Add check_admin_auth function
    - Add admin management functions
    - Add proper error handling

  2. Security
    - Update RLS policies
    - Add proper role checks
*/

-- Create admin check function
CREATE OR REPLACE FUNCTION check_admin_auth()
RETURNS boolean AS $$
DECLARE
  current_user_id uuid;
BEGIN
  -- Get current user's ID
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RETURN false;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = current_user_id
    AND is_admin = true
    AND status = 'approved'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update admin management functions
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
DO $$ 
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Admin full access" ON users;
  DROP POLICY IF EXISTS "Users read own data" ON users;
  DROP POLICY IF EXISTS "Users update own data" ON users;

  -- Create new policies
  CREATE POLICY "Admin full access" ON users
    FOR ALL USING (check_admin_auth());

  CREATE POLICY "Users read own data" ON users
    FOR SELECT USING (auth.uid() = id);

  CREATE POLICY "Users update own data" ON users
    FOR UPDATE USING (auth.uid() = id);
END $$;