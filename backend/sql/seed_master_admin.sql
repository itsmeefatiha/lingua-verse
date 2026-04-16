-- LinguaVerse master admin seed
-- Run after migrations. Requires pgcrypto for bcrypt-compatible hashing.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO users (
  email,
  hashed_password,
  full_name,
  role,
  source_language,
  target_language,
  is_active,
  total_xp,
  current_level,
  weekly_xp,
  current_league,
  streak_count,
  created_at
)
VALUES (
  'admin@linguaverse.local',
  crypt('ChangeThisPassword123!', gen_salt('bf')),
  'LinguaVerse Admin',
  (
    CASE
      WHEN EXISTS (
        SELECT 1
        FROM pg_type t
        JOIN pg_enum e ON e.enumtypid = t.oid
        WHERE t.typname = 'roleenum' AND e.enumlabel = 'admin'
      ) THEN 'admin'
      ELSE 'ADMIN'
    END
  )::roleenum,
  'en',
  'en',
  TRUE,
  0,
  1,
  0,
  'bronze',
  0,
  NOW()
)
ON CONFLICT (email) DO UPDATE SET
  hashed_password = EXCLUDED.hashed_password,
  full_name = EXCLUDED.full_name,
  role = EXCLUDED.role,
  source_language = EXCLUDED.source_language,
  target_language = EXCLUDED.target_language,
  is_active = EXCLUDED.is_active,
  total_xp = EXCLUDED.total_xp,
  current_level = EXCLUDED.current_level,
  weekly_xp = EXCLUDED.weekly_xp,
  current_league = EXCLUDED.current_league,
  streak_count = EXCLUDED.streak_count;

COMMIT;
