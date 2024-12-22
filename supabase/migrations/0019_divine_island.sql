/*
  # Fix Admin Authentication and Policies

  1. Changes
    - Update admin check function
    - Update RLS policies
    - Add registration helper function
  
  2. Security
    - Maintain secure admin checks
    - Allow public registration
    - Enable proper data access
*/

-- Update admin check function
CREATE OR REPLACE FUNCTION check_admin_auth()
RETURNS boolean AS $$
DECLARE
  current_user_id uuid;
BEGIN
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

-- Update RLS policies for users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Enable public registration" ON users;
DROP POLICY IF EXISTS "Enable read access" ON users;
DROP POLICY IF EXISTS "Enable update for own data" ON users;

-- Create new policies
CREATE POLICY "Enable insert for registration" ON users
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Enable select for all" ON users
  FOR SELECT USING (true);

CREATE POLICY "Enable update for owners and admins" ON users
  FOR UPDATE USING (
    auth.uid() = id OR 
    check_admin_auth()
  );

-- Add registration helper function
CREATE OR REPLACE FUNCTION register_user(
  name_param text,
  email_param text,
  phone_param text,
  dni_param text
) RETURNS uuid AS $$
DECLARE
  new_user_id uuid;
BEGIN
  INSERT INTO users (name, email, phone, dni, status)
  VALUES (name_param, email_param, phone_param, dni_param, 'pending')
  RETURNING id INTO new_user_id;
  
  RETURN new_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;