/*
  # Admin Approval System Update

  1. New Functions
    - approve_user: Function to approve a user
    - reject_user: Function to reject a user
    - approve_companion: Function to approve a companion
    - reject_companion: Function to reject a companion

  2. Security
    - Add admin role check functions
    - Add admin-specific policies
*/

-- Create admin role check function
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean AS $$
BEGIN
  -- Check if current user has admin role
  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND status = 'approved'
    AND email LIKE '%@fadiunc.org.ar'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create user approval function
CREATE OR REPLACE FUNCTION approve_user(user_id_param uuid)
RETURNS void AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE users
  SET status = 'approved'
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create user rejection function
CREATE OR REPLACE FUNCTION reject_user(user_id_param uuid)
RETURNS void AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE users
  SET status = 'rejected'
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create companion approval function
CREATE OR REPLACE FUNCTION approve_companion(companion_id_param uuid)
RETURNS void AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE companions
  SET status = 'approved'
  WHERE id = companion_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create companion rejection function
CREATE OR REPLACE FUNCTION reject_companion(companion_id_param uuid)
RETURNS void AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  UPDATE companions
  SET status = 'rejected'
  WHERE id = companion_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add admin policies
DO $$ 
BEGIN
  -- Users admin policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'users' 
    AND policyname = 'Admin can update users'
  ) THEN
    CREATE POLICY "Admin can update users" ON users
      FOR UPDATE USING (is_admin());
  END IF;

  -- Companions admin policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'companions' 
    AND policyname = 'Admin can update companions'
  ) THEN
    CREATE POLICY "Admin can update companions" ON companions
      FOR UPDATE USING (is_admin());
  END IF;
END $$;