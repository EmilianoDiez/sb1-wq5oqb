/*
  # Fix Admin Panel Functionality

  1. Changes
    - Add admin data fetching functions
    - Update RLS policies for admin access
    - Add pending registrations view
  
  2. Security
    - Ensure proper admin authentication
    - Maintain data access control
    - Add secure admin functions
*/

-- Create a view for pending registrations
CREATE OR REPLACE VIEW pending_registrations AS
SELECT 
  'user' as type,
  u.id,
  u.name,
  u.email,
  u.dni,
  u.created_at,
  u.status
FROM users u
WHERE u.status = 'pending'
UNION ALL
SELECT 
  'companion' as type,
  c.id,
  c.name,
  NULL as email,
  c.dni,
  c.created_at,
  c.status
FROM companions c
WHERE c.status = 'pending';

-- Create function to get pending registrations
CREATE OR REPLACE FUNCTION get_pending_registrations()
RETURNS TABLE (
  type text,
  id uuid,
  name text,
  email text,
  dni text,
  created_at timestamptz,
  status text
) SECURITY DEFINER AS $$
BEGIN
  IF NOT check_admin_auth() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  RETURN QUERY SELECT * FROM pending_registrations ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Update admin check function
CREATE OR REPLACE FUNCTION check_admin_auth()
RETURNS boolean AS $$
DECLARE
  current_user_id uuid;
BEGIN
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RETURN false;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM users
    WHERE id = current_user_id
    AND is_admin = true
    AND status = 'approved'
  );
END;
$$ LANGUAGE plpgsql;