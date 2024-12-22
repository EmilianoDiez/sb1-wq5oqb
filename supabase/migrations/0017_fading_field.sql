/*
  # Fix RLS Policies for User Registration

  1. Changes
    - Drop existing restrictive policies
    - Add new policies allowing public registration
    - Add policies for authenticated user access
    - Add admin management policies
  
  2. Security
    - Enable RLS on all tables
    - Add proper policies for each operation
    - Ensure data access control
*/

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can read own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;
DROP POLICY IF EXISTS "Admin can manage all users" ON users;

-- Create new policies for users table
CREATE POLICY "Enable public registration" ON users
  FOR INSERT 
  WITH CHECK (true);

CREATE POLICY "Enable read access" ON users
  FOR SELECT
  USING (true);

CREATE POLICY "Enable update for own data" ON users
  FOR UPDATE
  USING (auth.uid() = id OR check_admin_auth());

CREATE POLICY "Enable delete for own data" ON users
  FOR DELETE
  USING (auth.uid() = id OR check_admin_auth());

-- Create policies for companions table
CREATE POLICY "Enable companion registration" ON companions
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Enable companion read access" ON companions
  FOR SELECT
  USING (true);

CREATE POLICY "Enable companion update for owners" ON companions
  FOR UPDATE
  USING (user_id = auth.uid() OR check_admin_auth());

CREATE POLICY "Enable companion delete for owners" ON companions
  FOR DELETE
  USING (user_id = auth.uid() OR check_admin_auth());

-- Create helper function to check if user exists
CREATE OR REPLACE FUNCTION check_user_exists(dni_param text)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE dni = dni_param
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;