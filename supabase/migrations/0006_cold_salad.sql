/*
  # Add Users Table and Policies

  1. New Tables
    - Ensures users table exists with proper structure
    - Adds necessary indexes for performance
  2. Security
    - Enables RLS
    - Adds policies for user access
  3. Changes
    - Adds status check constraint
    - Adds unique constraint on DNI
*/

-- Create users table if it doesn't exist
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text UNIQUE NOT NULL,
  phone text,
  dni text UNIQUE NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Add policies
DO $$ 
BEGIN
  -- Allow users to read their own data
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'users' 
    AND policyname = 'Users can read own data'
  ) THEN
    CREATE POLICY "Users can read own data" ON users
      FOR SELECT USING (auth.uid() = id);
  END IF;

  -- Allow new user registration
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'users' 
    AND policyname = 'Allow user registration'
  ) THEN
    CREATE POLICY "Allow user registration" ON users
      FOR INSERT WITH CHECK (true);
  END IF;
END $$;

-- Add constraints
DO $$ 
BEGIN
  -- Add status check if it doesn't exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'users_status_check'
  ) THEN
    ALTER TABLE users 
      ADD CONSTRAINT users_status_check 
      CHECK (status IN ('pending', 'approved', 'rejected'));
  END IF;
END $$;

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_users_dni ON users(dni);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);