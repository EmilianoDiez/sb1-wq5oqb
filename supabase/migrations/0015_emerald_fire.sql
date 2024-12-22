/*
  # Fix Admin Authentication

  1. Functions
    - Add admin check function with proper error handling
    - Add admin management functions with proper permissions
    - Add companion management functions

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

  -- Check if user is admin and approved
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = current_user_id
    AND is_admin = true
    AND status = 'approved'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create admin management functions
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

-- Update RLS policies
DO $$ 
BEGIN
  -- Drop existing policies
  DROP POLICY IF EXISTS "Admin full access" ON users;
  DROP POLICY IF EXISTS "Users read own data" ON users;
  DROP POLICY IF EXISTS "Users update own data" ON users;
  DROP POLICY IF EXISTS "Admin full access" ON companions;
  DROP POLICY IF EXISTS "Users read own companions" ON companions;

  -- Create new policies
  CREATE POLICY "Admin full access" ON users
    FOR ALL USING (check_admin_auth());

  CREATE POLICY "Users read own data" ON users
    FOR SELECT USING (auth.uid() = id);

  CREATE POLICY "Users update own data" ON users
    FOR UPDATE USING (auth.uid() = id);

  CREATE POLICY "Admin full access" ON companions
    FOR ALL USING (check_admin_auth());

  CREATE POLICY "Users read own companions" ON companions
    FOR SELECT USING (user_id = auth.uid());
END $$;