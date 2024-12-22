/*
  # Fix Database Schema

  1. Tables
    - Ensures all required tables exist with proper constraints
  2. Security
    - Enables RLS and adds necessary policies
  3. Indexes
    - Adds performance optimization indexes
*/

-- Create users table if not exists
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text UNIQUE NOT NULL,
  phone text,
  dni text UNIQUE NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz DEFAULT now()
);

-- Create companions table if not exists
CREATE TABLE IF NOT EXISTS companions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  name text NOT NULL,
  dni text NOT NULL,
  age integer NOT NULL CHECK (age >= 0 AND age <= 120),
  phone text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz DEFAULT now()
);

-- Create reservations table if not exists
CREATE TABLE IF NOT EXISTS reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  date date NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  created_at timestamptz DEFAULT now()
);

-- Create entries table if not exists
CREATE TABLE IF NOT EXISTS entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  companion_id uuid REFERENCES companions(id) ON DELETE CASCADE,
  entry_date date NOT NULL DEFAULT CURRENT_DATE,
  entry_time time NOT NULL DEFAULT CURRENT_TIME,
  type text NOT NULL CHECK (type IN ('affiliate', 'companion')),
  price numeric(10,2) NOT NULL DEFAULT 0,
  discount integer NOT NULL DEFAULT 0 CHECK (discount >= 0 AND discount <= 100),
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE companions ENABLE ROW LEVEL SECURITY;
ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE entries ENABLE ROW LEVEL SECURITY;

-- Add policies with existence checks
DO $$ 
BEGIN
  -- Users policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'users' 
    AND policyname = 'Allow public read'
  ) THEN
    CREATE POLICY "Allow public read" ON users
      FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'users' 
    AND policyname = 'Allow public insert'
  ) THEN
    CREATE POLICY "Allow public insert" ON users
      FOR INSERT WITH CHECK (true);
  END IF;

  -- Companions policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'companions' 
    AND policyname = 'Allow public read'
  ) THEN
    CREATE POLICY "Allow public read" ON companions
      FOR SELECT USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'companions' 
    AND policyname = 'Allow public insert'
  ) THEN
    CREATE POLICY "Allow public insert" ON companions
      FOR INSERT WITH CHECK (true);
  END IF;

  -- Reservations policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'reservations' 
    AND policyname = 'Allow public read'
  ) THEN
    CREATE POLICY "Allow public read" ON reservations
      FOR SELECT USING (true);
  END IF;

  -- Entries policies
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'entries' 
    AND policyname = 'Allow public read'
  ) THEN
    CREATE POLICY "Allow public read" ON entries
      FOR SELECT USING (true);
  END IF;
END $$;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_dni ON users(dni);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_companions_user_id ON companions(user_id);
CREATE INDEX IF NOT EXISTS idx_companions_dni ON companions(dni);
CREATE INDEX IF NOT EXISTS idx_reservations_user_date ON reservations(user_id, date);
CREATE INDEX IF NOT EXISTS idx_entries_user_date ON entries(user_id, entry_date);