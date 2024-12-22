/*
  # Fix RLS Policies and User Registration

  1. Changes
    - Add public insert policies for users and companions
    - Fix admin authentication
    - Update existing policies

  2. Security
    - Maintain RLS while allowing registration
    - Ensure proper admin access
*/

-- Drop existing policies
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Admin full access" ON users;
  DROP POLICY IF EXISTS "Users read own data" ON users;
  DROP POLICY IF EXISTS "Users update own data" ON users;
  DROP POLICY IF EXISTS "Admin full access" ON companions;
  DROP POLICY IF EXISTS "Users read own companions" ON companions;
END $$;

-- Create new policies for users
CREATE POLICY "Allow public registration" ON users
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can read own data" ON users
  FOR SELECT USING (auth.uid() = id OR check_admin_auth());

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id OR check_admin_auth());

CREATE POLICY "Admin can manage all users" ON users
  FOR ALL USING (check_admin_auth());

-- Create new policies for companions
CREATE POLICY "Allow companion registration" ON companions
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can read own companions" ON companions
  FOR SELECT USING (user_id = auth.uid() OR check_admin_auth());

CREATE POLICY "Users can update own companions" ON companions
  FOR UPDATE USING (user_id = auth.uid() OR check_admin_auth());

CREATE POLICY "Admin can manage all companions" ON companions
  FOR ALL USING (check_admin_auth());