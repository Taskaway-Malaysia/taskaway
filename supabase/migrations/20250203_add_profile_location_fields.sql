-- Migration: Add location and availability fields to profiles
-- Date: 2025-02-03
-- Purpose: Enable tasker location tracking and availability status for the "Find Tasker" feature

-- Add location and availability columns to taskaway_profiles
ALTER TABLE taskaway_profiles
ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
ADD COLUMN IF NOT EXISTS is_available BOOLEAN DEFAULT true;

-- Add index on location columns for faster proximity queries
CREATE INDEX IF NOT EXISTS idx_profiles_location
ON taskaway_profiles(latitude, longitude)
WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- Add index on availability for faster filtering
CREATE INDEX IF NOT EXISTS idx_profiles_availability
ON taskaway_profiles(is_available)
WHERE role = 'tasker';

-- Add combined index for common query pattern (role + availability + location)
CREATE INDEX IF NOT EXISTS idx_profiles_tasker_available_location
ON taskaway_profiles(role, is_available, latitude, longitude)
WHERE role = 'tasker' AND is_available = true;

-- Add comment to document the fields
COMMENT ON COLUMN taskaway_profiles.latitude IS 'Tasker location latitude for proximity search';
COMMENT ON COLUMN taskaway_profiles.longitude IS 'Tasker location longitude for proximity search';
COMMENT ON COLUMN taskaway_profiles.is_available IS 'Whether tasker is currently available to accept tasks';

-- Optional: Create a view for available taskers with location
CREATE OR REPLACE VIEW tasker_locations AS
SELECT
  id,
  full_name,
  avatar_url,
  skills,
  rating,
  total_tasks,
  latitude,
  longitude,
  bio,
  about
FROM taskaway_profiles
WHERE role = 'tasker'
  AND is_available = true
  AND latitude IS NOT NULL
  AND longitude IS NOT NULL;

COMMENT ON VIEW tasker_locations IS 'Available taskers with location data for the Find Tasker feature';
