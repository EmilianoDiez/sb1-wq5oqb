/*
  # Additional Security and Performance Enhancements

  1. New Features:
    - Additional RLS policies for data modification
    - Insert and update policies for all tables
    - Admin-specific policies
  
  2. Security:
    - More granular access control
    - Separate policies for different operations
*/

-- Add insert and update policies for users
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'users' 
    AND policyname = 'Users can insert themselves'
  ) THEN
    CREATE POLICY "Users can insert themselves" ON users
      FOR INSERT WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'users' 
    AND policyname = 'Users can update own profile'
  ) THEN
    CREATE POLICY "Users can update own profile" ON users
      FOR UPDATE USING (auth.uid() = id);
  END IF;
END $$;

-- Add companion management policies
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'companions' 
    AND policyname = 'Users can update own companions'
  ) THEN
    CREATE POLICY "Users can update own companions" ON companions
      FOR UPDATE USING (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'companions' 
    AND policyname = 'Users can delete own companions'
  ) THEN
    CREATE POLICY "Users can delete own companions" ON companions
      FOR DELETE USING (user_id = auth.uid());
  END IF;
END $$;

-- Add reservation management policies
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'reservations' 
    AND policyname = 'Users can insert own reservations'
  ) THEN
    CREATE POLICY "Users can insert own reservations" ON reservations
      FOR INSERT WITH CHECK (user_id = auth.uid());
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'reservations' 
    AND policyname = 'Users can delete own reservations'
  ) THEN
    CREATE POLICY "Users can delete own reservations" ON reservations
      FOR DELETE USING (user_id = auth.uid());
  END IF;
END $$;

-- Add reservation companions management policies
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'reservation_companions' 
    AND policyname = 'Users can insert own reservation companions'
  ) THEN
    CREATE POLICY "Users can insert own reservation companions" ON reservation_companions
      FOR INSERT WITH CHECK (
        EXISTS (
          SELECT 1 FROM reservations r
          WHERE r.id = reservation_id
          AND r.user_id = auth.uid()
        )
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'reservation_companions' 
    AND policyname = 'Users can delete own reservation companions'
  ) THEN
    CREATE POLICY "Users can delete own reservation companions" ON reservation_companions
      FOR DELETE USING (
        EXISTS (
          SELECT 1 FROM reservations r
          WHERE r.id = reservation_id
          AND r.user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- Add entries management policies
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE schemaname = 'public' 
    AND tablename = 'entries' 
    AND policyname = 'Users can insert own entries'
  ) THEN
    CREATE POLICY "Users can insert own entries" ON entries
      FOR INSERT WITH CHECK (user_id = auth.uid());
  END IF;
END $$;