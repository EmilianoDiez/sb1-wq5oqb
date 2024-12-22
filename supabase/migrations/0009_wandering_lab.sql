/*
  # Fix Database Schema and Permissions

  1. Tables
    - Recreates all tables with proper constraints
    - Adds necessary indexes for performance
  
  2. Security
    - Enables RLS on all tables
    - Adds public access policies for initial setup
    - Sets up proper constraints and checks

  3. Changes
    - Removes duplicate policies
    - Fixes table relationships
    - Adds proper type constraints
*/

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS entries CASCADE;
DROP TABLE IF EXISTS reservations CASCADE;
DROP TABLE IF EXISTS companions CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Create users table
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text UNIQUE NOT NULL,
  phone text,
  dni text UNIQUE NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz DEFAULT now()
);

-- Create companions table
CREATE TABLE companions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  name text NOT NULL,
  dni text NOT NULL,
  age integer NOT NULL CHECK (age >= 0 AND age <= 120),
  phone text,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  created_at timestamptz DEFAULT now()
);

-- Create reservations table
CREATE TABLE reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  date date NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
  created_at timestamptz DEFAULT now()
);

-- Create entries table
CREATE TABLE entries (
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

-- Create indexes
CREATE INDEX idx_users_dni ON users(dni);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_companions_user_id ON companions(user_id);
CREATE INDEX idx_companions_dni ON companions(dni);
CREATE INDEX idx_reservations_user_date ON reservations(user_id, date);
CREATE INDEX idx_entries_user_date ON entries(user_id, entry_date);

-- Add RLS policies
-- Users policies
CREATE POLICY "Allow public read" ON users FOR SELECT USING (true);
CREATE POLICY "Allow public insert" ON users FOR INSERT WITH CHECK (true);

-- Companions policies
CREATE POLICY "Allow public read" ON companions FOR SELECT USING (true);
CREATE POLICY "Allow public insert" ON companions FOR INSERT WITH CHECK (true);

-- Reservations policies
CREATE POLICY "Allow public read" ON reservations FOR SELECT USING (true);
CREATE POLICY "Allow public insert" ON reservations FOR INSERT WITH CHECK (true);

-- Entries policies
CREATE POLICY "Allow public read" ON entries FOR SELECT USING (true);
CREATE POLICY "Allow public insert" ON entries FOR INSERT WITH CHECK (true);