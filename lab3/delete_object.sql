DROP TRIGGER IF EXISTS trg_max_hashtags ON post_hashtags;
DROP FUNCTION IF EXISTS check_max_hashtags();
DROP TABLE IF EXISTS post_files;
DROP TABLE IF EXISTS post_hashtags;
DROP TABLE IF EXISTS hashtags;
DROP TABLE IF EXISTS posts;
ALTER TABLE IF EXISTS users DROP CONSTRAINT IF EXISTS fk_user_avatar;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS files;