/*
  # Initial Schema Setup

  1. New Tables
    - `users`
      - `id` (uuid, primary key)
      - `name` (text)
      - `email` (text)
      - `phone` (text)
      - `dni` (text)
      - `status` (text)
      - `created_at` (timestamp)
    
    - `companions`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key)
      - `name` (text)
      - `dni` (text)
      - `age` (integer)
      - `phone` (text)
      - `status` (text)
      - `created_at` (timestamp)
    
    - `reservations`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key)
      - `date` (date)
      - `status` (text)
      - `created_at` (timestamp)
    
    - `reservation_companions`
      - `id` (uuid, primary key)
      - `reservation_id` (uuid, foreign key)
      - `companion_id` (uuid, foreign key)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users
*/

-- Users table
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  email text UNIQUE NOT NULL,
  phone text,
  dni text UNIQUE NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own data"
  ON users
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Companions table
CREATE TABLE companions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  name text NOT NULL,
  dni text NOT NULL,
  age integer NOT NULL,
  phone text,
  status text NOT NULL DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE companions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own companions"
  ON companions
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Reservations table
CREATE TABLE reservations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  date date NOT NULL,
  status text NOT NULL DEFAULT 'active',
  created_at timestamptz DEFAULT now()
);

ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own reservations"
  ON reservations
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Reservation companions junction table
CREATE TABLE reservation_companions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reservation_id uuid REFERENCES reservations(id) ON DELETE CASCADE,
  companion_id uuid REFERENCES companions(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(reservation_id, companion_id)
);

ALTER TABLE reservation_companions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own reservation companions"
  ON reservation_companions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM reservations r
      WHERE r.id = reservation_id
      AND r.user_id = auth.uid()
    )
  );