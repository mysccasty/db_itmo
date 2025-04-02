INSERT INTO users (username, email, phone, password_hash, first_name, last_name, status, created_at, updated_at)
VALUES
    ('ivan_88', 'ivan@example.com', '+79161234567', '5f4dcc3b5aa765d61d8327deb882cf99', 'Иван', 'Петров', 'active', '2023-01-15 10:00:00+03', '2023-01-15 10:00:00+03'),
    ('anna_smith', 'anna@example.com', '+79031234567', '482c811da5d5b4bc6d497ffa98491e38', 'Анна', 'Смирнова', 'active', '2023-02-20 14:30:00+03', '2023-02-20 14:30:00+03'),
    ('max_developer', 'max@example.com', NULL, 'b1b3773a05c0ed0176787a4f1574ff00', 'Максим', 'Иванов', 'active', '2023-03-10 09:15:00+03', '2023-03-10 09:15:00+03');

INSERT INTO files (type, path, filename, uploaded_at)
VALUES
    ('image', '/uploads/avatars', 'ivan_avatar.jpg', '2023-01-15 10:05:00+03'),
    ('image', '/uploads/avatars', 'anna_avatar.png', '2023-02-20 14:35:00+03'),
    ('image', '/uploads/posts', 'sunset.jpg', '2023-03-01 18:00:00+03'),
    ('video', '/uploads/posts', 'tutorial.mp4', '2023-03-05 12:00:00+03'),
    ('image', '/uploads/posts', 'cat_meme.jpg', '2023-03-12 16:45:00+03');

UPDATE users SET avatar_id = 1 WHERE username = 'ivan_88';
UPDATE users SET avatar_id = 2 WHERE username = 'anna_smith';

INSERT INTO hashtags (slug)
VALUES
    ('travel'),
    ('programming'),
    ('food'),
    ('cats'),
    ('photography');

INSERT INTO posts (user_id, description, status, created_at, updated_at)
VALUES (1, 'Красивый закат на море #travel #photography', 'published', '2023-03-01 18:05:00+03',
        '2023-03-01 18:05:00+03'),
    (3, 'Как я решил проблему с SQL-запросом #programming', 'published', '2023-03-10 09:20:00+03',
        '2023-03-10 09:20:00+03');
INSERT INTO posts (user_id, description, status, created_at)
VALUES (2, 'Мой новый рецепт пасты #food', 'published', '2023-03-05 12:10:00+03');
INSERT INTO posts (user_id, description, status)
VALUES (1, 'Смешной котик #cats #photography', 'published');

INSERT INTO post_files (post_id, file_id)
VALUES
    (1, 3),
    (2, 4),
    (4, 5);

INSERT INTO post_hashtags (post_id, hashtag_id)
VALUES
    (1, 1),
    (1, 5),
    (2, 2),
    (3, 3),
    (4, 4),
    (4, 5);