-- LinguaVerse learning engine seed data
-- Run after migrations (including e4b1c2d3f6a7_add_languages_table_and_link_levels)

BEGIN;

-- 1) Languages (dynamic source for /content/languages)
INSERT INTO languages (name, code)
VALUES
  ('English', 'en'),
  ('French', 'fr'),
  ('Spanish', 'es'),
  ('German', 'de'),
  ('Arabic', 'ar')
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name;

-- 2) Clean existing catalog content for predictable tests
DELETE FROM questions;
DELETE FROM user_viewed_vocab;
DELETE FROM user_lesson_progress;
DELETE FROM vocabularies;
DELETE FROM lessons;
DELETE FROM levels;

-- 3) Insert levels per language (A1, A2)
WITH lang AS (
  SELECT id, code FROM languages WHERE code IN ('fr', 'es')
)
INSERT INTO levels (code, language_id, display_order)
SELECT 'A1'::cefrlevelenum, id, 1 FROM lang
UNION ALL
SELECT 'A2'::cefrlevelenum, id, 2 FROM lang;

-- 4) Lessons per level per language
WITH level_rows AS (
  SELECT l.id, lg.code AS language_code, l.code AS level_code
  FROM levels l
  JOIN languages lg ON lg.id = l.language_id
  WHERE lg.code IN ('fr', 'es')
)
INSERT INTO lessons (title, description, level_id, display_order, created_at)
SELECT
  CASE
    WHEN language_code = 'fr' AND level_code = 'A1' THEN 'FR A1 - Basics 1'
    WHEN language_code = 'fr' AND level_code = 'A2' THEN 'FR A2 - Basics 2'
    WHEN language_code = 'es' AND level_code = 'A1' THEN 'ES A1 - Basics 1'
    WHEN language_code = 'es' AND level_code = 'A2' THEN 'ES A2 - Basics 2'
  END,
  CASE
    WHEN language_code = 'fr' AND level_code = 'A1' THEN 'French beginner vocabulary set 1'
    WHEN language_code = 'fr' AND level_code = 'A2' THEN 'French beginner vocabulary set 2'
    WHEN language_code = 'es' AND level_code = 'A1' THEN 'Spanish beginner vocabulary set 1'
    WHEN language_code = 'es' AND level_code = 'A2' THEN 'Spanish beginner vocabulary set 2'
  END,
  id,
  1,
  NOW()
FROM level_rows
UNION ALL
SELECT
  CASE
    WHEN language_code = 'fr' AND level_code = 'A1' THEN 'FR A1 - Daily words'
    WHEN language_code = 'fr' AND level_code = 'A2' THEN 'FR A2 - Daily words'
    WHEN language_code = 'es' AND level_code = 'A1' THEN 'ES A1 - Daily words'
    WHEN language_code = 'es' AND level_code = 'A2' THEN 'ES A2 - Daily words'
  END,
  CASE
    WHEN language_code = 'fr' AND level_code = 'A1' THEN 'French common daily words'
    WHEN language_code = 'fr' AND level_code = 'A2' THEN 'French practical daily words'
    WHEN language_code = 'es' AND level_code = 'A1' THEN 'Spanish common daily words'
    WHEN language_code = 'es' AND level_code = 'A2' THEN 'Spanish practical daily words'
  END,
  id,
  2,
  NOW()
FROM level_rows;

-- 5) Words for each lesson (native_text <- translation, target_text <- term)
WITH lesson_rows AS (
  SELECT id, title FROM lessons
)
INSERT INTO vocabularies (category, term, translation, example, image_url, audio_url, lesson_id)
SELECT
  'general',
  CASE
    WHEN title LIKE 'FR A1%' THEN 'bonjour'
    WHEN title LIKE 'FR A2%' THEN 'apprendre'
    WHEN title LIKE 'ES A1%' THEN 'hola'
    WHEN title LIKE 'ES A2%' THEN 'aprender'
  END,
  CASE
    WHEN title LIKE 'FR A1%' THEN 'hello'
    WHEN title LIKE 'FR A2%' THEN 'to learn'
    WHEN title LIKE 'ES A1%' THEN 'hello'
    WHEN title LIKE 'ES A2%' THEN 'to learn'
  END,
  'seed word 1',
  NULL,
  NULL,
  id
FROM lesson_rows
UNION ALL
SELECT
  'general',
  CASE
    WHEN title LIKE 'FR A1%' THEN 'merci'
    WHEN title LIKE 'FR A2%' THEN 'ecole'
    WHEN title LIKE 'ES A1%' THEN 'gracias'
    WHEN title LIKE 'ES A2%' THEN 'escuela'
  END,
  CASE
    WHEN title LIKE 'FR A1%' THEN 'thank you'
    WHEN title LIKE 'FR A2%' THEN 'school'
    WHEN title LIKE 'ES A1%' THEN 'thank you'
    WHEN title LIKE 'ES A2%' THEN 'school'
  END,
  'seed word 2',
  NULL,
  NULL,
  id
FROM lesson_rows
UNION ALL
SELECT
  'general',
  CASE
    WHEN title LIKE 'FR A1%' THEN 'au revoir'
    WHEN title LIKE 'FR A2%' THEN 'maison'
    WHEN title LIKE 'ES A1%' THEN 'adios'
    WHEN title LIKE 'ES A2%' THEN 'casa'
  END,
  CASE
    WHEN title LIKE 'FR A1%' THEN 'goodbye'
    WHEN title LIKE 'FR A2%' THEN 'house'
    WHEN title LIKE 'ES A1%' THEN 'goodbye'
    WHEN title LIKE 'ES A2%' THEN 'house'
  END,
  'seed word 3',
  NULL,
  NULL,
  id
FROM lesson_rows;

-- 6) Simple quiz questions per lesson for level-gating tests
INSERT INTO questions (text, question_type, correct_answer, grammatical_explanation, lesson_id, vocabulary_id, concept_id)
SELECT
  'Choose the correct translation for the highlighted word.',
  'QCM',
  v.translation,
  'Seed auto-question',
  v.lesson_id,
  v.id,
  'seed-qcm'
FROM vocabularies v;

COMMIT;
