/*
  # Fix Registration Policies and Constraints

  1. Changes
    - Safely update RLS policies for registration
    - Add unique constraints for DNI
    - Add safe registration function
  
  2. Security
    - Enable RLS on tables
    - Update policies for public registration
    - Add function for safe user registration
*/

-- Safely update RLS policies
DO $$ 
BEGIN
  -- Drop existing policies if they exist
  DROP POLICY IF EXISTS "Enable insert for registration" ON users;
  DROP POLICY IF EXISTS "Enable companion registration" ON companions;
  DROP POLICY IF EXISTS "Allow public registration" ON users;
  DROP POLICY IF EXISTS "Allow companion registration" ON companions;

  -- Create new policies with unique names
  CREATE POLICY "Enable public user registration" ON users
    FOR INSERT WITH CHECK (true);

  CREATE POLICY "Enable public companion registration" ON companions
    FOR INSERT WITH CHECK (true);
END $$;

-- Add unique constraints (only if they don't exist)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_dni_unique'
  ) THEN
    ALTER TABLE users 
      ADD CONSTRAINT users_dni_unique UNIQUE (dni);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'companions_dni_user_unique'
  ) THEN
    ALTER TABLE companions
      ADD CONSTRAINT companions_dni_user_unique UNIQUE (dni, user_id);
  END IF;
END $$;

-- Add function for safe user registration
CREATE OR REPLACE FUNCTION register_user_safely(
  name_param text,
  email_param text,
  dni_param text,
  phone_param text
) RETURNS uuid AS $$
DECLARE
  new_user_id uuid;
BEGIN
  -- Check for existing user
  IF EXISTS (SELECT 1 FROM users WHERE dni = dni_param) THEN
    RAISE EXCEPTION 'Ya existe un usuario registrado con este DNI';
  END IF;

  IF EXISTS (SELECT 1 FROM users WHERE email = email_param) THEN
    RAISE EXCEPTION 'Ya existe un usuario registrado con este email';
  END IF;

  -- Insert new user
  INSERT INTO users (name, email, dni, phone, status)
  VALUES (name_param, email_param, dni_param, phone_param, 'pending')
  RETURNING id INTO new_user_id;

  RETURN new_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;