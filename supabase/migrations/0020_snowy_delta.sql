/*
  # Update Admin Functions and Policies

  1. Changes
    - Drop and recreate get_pending_registrations function
    - Add approval tracking columns
    - Update admin approval functions
  
  2. Security
    - Maintain admin authorization checks
    - Add approval tracking
*/

-- Drop existing function first
DROP FUNCTION IF EXISTS get_pending_registrations();

-- Add approval tracking columns
ALTER TABLE users ADD COLUMN IF NOT EXISTS approved_at timestamptz;
ALTER TABLE users ADD COLUMN IF NOT EXISTS approved_by uuid REFERENCES users(id);
ALTER TABLE companions ADD COLUMN IF NOT EXISTS approved_at timestamptz;
ALTER TABLE companions ADD COLUMN IF NOT EXISTS approved_by uuid REFERENCES users(id);

-- Create new get_pending_registrations function with updated return type
CREATE OR REPLACE FUNCTION get_pending_registrations()
RETURNS TABLE (
  type text,
  id uuid,
  name text,
  email text,
  dni text,
  created_at timestamptz,
  status text,
  approved_at timestamptz,
  approved_by_name text
) SECURITY DEFINER AS $$
BEGIN
  IF NOT check_admin_auth() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  RETURN QUERY 
    SELECT 
      'user'::text as type,
      u.id,
      u.name,
      u.email,
      u.dni,
      u.created_at,
      u.status,
      u.approved_at,
      approver.name as approved_by_name
    FROM users u
    LEFT JOIN users approver ON u.approved_by = approver.id
    WHERE u.status = 'pending'
    UNION ALL
    SELECT 
      'companion'::text as type,
      c.id,
      c.name,
      NULL as email,
      c.dni,
      c.created_at,
      c.status,
      c.approved_at,
      approver.name as approved_by_name
    FROM companions c
    LEFT JOIN users approver ON c.approved_by = approver.id
    WHERE c.status = 'pending'
    ORDER BY created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Update admin approval functions to track approvals
CREATE OR REPLACE FUNCTION admin_approve_user(user_id_param uuid)
RETURNS void AS $$
BEGIN
  IF NOT check_admin_auth() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  UPDATE users
  SET 
    status = 'approved',
    approved_at = CURRENT_TIMESTAMP,
    approved_by = auth.uid()
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION admin_reject_user(user_id_param uuid)
RETURNS void AS $$
BEGIN
  IF NOT check_admin_auth() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  UPDATE users
  SET 
    status = 'rejected',
    approved_at = CURRENT_TIMESTAMP,
    approved_by = auth.uid()
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION admin_approve_companion(companion_id_param uuid)
RETURNS void AS $$
BEGIN
  IF NOT check_admin_auth() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  UPDATE companions
  SET 
    status = 'approved',
    approved_at = CURRENT_TIMESTAMP,
    approved_by = auth.uid()
  WHERE id = companion_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION admin_reject_companion(companion_id_param uuid)
RETURNS void AS $$
BEGIN
  IF NOT check_admin_auth() THEN
    RAISE EXCEPTION 'Unauthorized: Admin access required';
  END IF;

  UPDATE companions
  SET 
    status = 'rejected',
    approved_at = CURRENT_TIMESTAMP,
    approved_by = auth.uid()
  WHERE id = companion_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;