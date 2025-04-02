CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    status VARCHAR(20) NOT NULL CHECK (status IN ('active', 'banned', 'deleted')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    avatar_id BIGINT
);

CREATE TABLE files (
    id BIGSERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    path VARCHAR(255) NOT NULL,
    filename VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL CHECK (status IN ('draft', 'published', 'archived')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE hashtags (
    id BIGSERIAL PRIMARY KEY,
    slug VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE post_hashtags (
    post_id BIGINT NOT NULL,
    hashtag_id BIGINT NOT NULL,
    PRIMARY KEY (post_id, hashtag_id)
);

CREATE TABLE post_files (
    post_id BIGINT NOT NULL,
    file_id BIGINT NOT NULL,
    PRIMARY KEY (post_id, file_id)
);

ALTER TABLE users ADD CONSTRAINT fk_user_avatar
FOREIGN KEY (avatar_id) REFERENCES files(id)
ON DELETE SET NULL;

ALTER TABLE posts ADD CONSTRAINT fk_post_user
FOREIGN KEY (user_id) REFERENCES users(id)
ON DELETE CASCADE;

ALTER TABLE post_hashtags ADD CONSTRAINT fk_post_hashtag_post
FOREIGN KEY (post_id) REFERENCES posts(id)
ON DELETE CASCADE;

ALTER TABLE post_hashtags ADD CONSTRAINT fk_post_hashtag_hashtag
FOREIGN KEY (hashtag_id) REFERENCES hashtags(id)
ON DELETE CASCADE;

ALTER TABLE post_files ADD CONSTRAINT fk_post_file_post
FOREIGN KEY (post_id) REFERENCES posts(id)
ON DELETE CASCADE;

ALTER TABLE post_files ADD CONSTRAINT fk_post_file_file
FOREIGN KEY (file_id) REFERENCES files(id)
ON DELETE CASCADE;
ALTER TABLE users ADD CONSTRAINT ck_user_email_format
CHECK (email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$');

ALTER TABLE users ADD CONSTRAINT ck_user_phone_format
CHECK (phone ~ '^\+?[0-9]{10,15}$');

ALTER TABLE files ADD CONSTRAINT ck_file_type
CHECK (type IN ('image', 'video', 'audio', 'document', 'archive'));

ALTER TABLE files ADD CONSTRAINT ck_filename_no_special_chars
CHECK (filename !~ '[\\/\:\*\?"<>\|]');

CREATE OR REPLACE FUNCTION check_max_hashtags()
RETURNS TRIGGER AS $$
DECLARE
    hashtag_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO hashtag_count
    FROM post_hashtags
    WHERE post_id = NEW.post_id;

    IF hashtag_count >= 10 THEN
        RAISE EXCEPTION 'Maximum 10 hashtags per post allowed';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_max_hashtags
BEFORE INSERT OR UPDATE ON post_hashtags
FOR EACH ROW EXECUTE FUNCTION check_max_hashtags();