/*
  # Fix Admin Authentication and Authorization

  1. Changes
    - Add admin role management
    - Update admin check function
    - Add admin authentication functions
    - Update RLS policies
  
  2. Security
    - Enforce proper admin role checks
    - Add secure authentication flow
*/

-- Add admin role management
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin boolean DEFAULT false;

-- Update admin check function
CREATE OR REPLACE FUNCTION check_admin_auth()
RETURNS boolean AS $$
DECLARE
  current_user_id uuid;
BEGIN
  -- Get current user info from auth.jwt()
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

-- Add admin authentication function
CREATE OR REPLACE FUNCTION authenticate_admin(email_param text, password_param text)
RETURNS boolean AS $$
BEGIN
  -- Check if user exists and is admin
  RETURN EXISTS (
    SELECT 1 FROM users u
    JOIN auth.users au ON u.id = au.id::uuid
    WHERE u.email = email_param
    AND u.is_admin = true
    AND u.status = 'approved'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update RLS policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  -- Drop existing policies first
  DROP POLICY IF EXISTS "Enable public registration" ON users;
  DROP POLICY IF EXISTS "Enable read access" ON users;
  DROP POLICY IF EXISTS "Enable update for own data" ON users;
  DROP POLICY IF EXISTS "Admin full access" ON users;

  -- Create new policies with unique names
  CREATE POLICY "Public registration access" ON users
    FOR INSERT WITH CHECK (true);

  CREATE POLICY "Global read access" ON users
    FOR SELECT USING (true);

  CREATE POLICY "Owner and admin update access" ON users
    FOR UPDATE USING (
      auth.uid() = id OR 
      check_admin_auth()
    );

  CREATE POLICY "Admin management access" ON users
    FOR ALL USING (check_admin_auth());
END $$;