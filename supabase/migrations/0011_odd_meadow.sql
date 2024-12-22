/*
  # Fix Admin Authentication

  1. Changes
    - Add admin role to users table
    - Update is_admin function
    - Add admin-specific policies
    - Fix RLS policies for admin operations

  2. Security
    - Ensure proper admin role checks
    - Add secure policies for admin operations
*/

-- Add admin role to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin boolean DEFAULT false;

-- Update is_admin function to use the new column
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND is_admin = true
    AND status = 'approved'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update admin policies
DO $$ 
BEGIN
  -- Drop existing policies
  DROP POLICY IF EXISTS "Admin can update users" ON users;
  DROP POLICY IF EXISTS "Admin can update companions" ON companions;
  DROP POLICY IF EXISTS "Allow public read" ON users;
  DROP POLICY IF EXISTS "Allow public read" ON companions;

  -- Create new policies
  CREATE POLICY "Admin can read all" ON users
    FOR SELECT USING (is_admin() OR id = auth.uid());

  CREATE POLICY "Admin can update all" ON users
    FOR UPDATE USING (is_admin());

  CREATE POLICY "Admin can read companions" ON companions
    FOR SELECT USING (is_admin() OR user_id = auth.uid());

  CREATE POLICY "Admin can update companions" ON companions
    FOR UPDATE USING (is_admin());

  -- Add policy for admin management
  CREATE POLICY "Admin can manage admins" ON users
    FOR ALL USING (is_admin());
END $$;