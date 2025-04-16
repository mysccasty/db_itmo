# Лабораторная работа 4
### Выполнил:
* Кузнецов Владимир
* Группа P4150
* Дата выполнения: 09.04.2025
* Наименование дисциплины: Взаимодействие с базами данных

## Текст задания
1. Описать бизнес-правила вашей предметной области. Какие в вашей системе могут быть действия, требующие выполнения запроса в БД. Эти бизнес-правила будут использованы для реализации триггеров, функций, процедур, транзакций поэтому приниматься будут только достаточно интересные бизнес-правила
2. Добавить в ранее созданную базу данных триггеры для обеспечения комплексных ограничений целостности. Триггеров должно быть не менее трех
3. Реализовать функции и процедуры на основе описания бизнес-процессов, определенных при описании предметной области из пункта 1. Примеров не менее 3
4. Привести 3 примера выполнения транзакции. Это может быть, например, проверка корректности вводимых данных для созданных функций и процедур. Например, функция, которая вносит данные. Данные проверяются и в случае если они не подходят ограничениям целостности, транзакция должна откатываться
5. Необходимо произвести анализ использования созданной базы данных, выявить наиболее часто используемые объекты базы данных, виды запросов к ним. Результаты должны быть представлены в виде текстового описания
6. На основании полученного описания требуется создать подходящие индексы и доказать, что они будут полезны для представленных в описании случаев использования базы данных.
---
## Бизнес-правила  
1. При блокировке пользователя все его посты должны архивироваться
2. Нельзя создать пустой пост(пост без файлов и текста)
3. Ограничение на частоту публикаций - пользователь не может публиковать более 5 постов в час
4. После добавления поста необходимо автоматически определять хештеги
5. Пользователь может добавить в качестве аватара файл типа image
---
## Тригеры
### Запрет на создание постов для заблокированных пользователей
```sql
CREATE OR REPLACE FUNCTION prevent_posts_from_banned_users()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
DECLARE
    user_status VARCHAR(20);
BEGIN
    SELECT status INTO user_status
    FROM users
    WHERE id = NEW.user_id;
    
    IF user_status = 'banned' THEN
        RAISE EXCEPTION 'User is not allowed to create posts';
    END IF;
    
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_prevent_banned_user_posts
BEFORE INSERT ON posts
FOR EACH ROW
EXECUTE FUNCTION prevent_posts_from_banned_users();
```
### Ограничение на частоту публикаций - пользователь не может публиковать более 5 постов в час
```sql
CREATE OR REPLACE FUNCTION check_post_limit_per_hour()
RETURNS TRIGGER AS $$
DECLARE
    post_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO post_count
    FROM posts
    WHERE user_id = NEW.user_id
    AND created_at > NOW() - INTERVAL '1 hour';

    IF post_count >= 5 THEN
        RAISE EXCEPTION 'Only 5 posts are available to create per hour.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_post_limit_per_hour
BEFORE INSERT ON posts
FOR EACH ROW EXECUTE FUNCTION check_post_limit_per_hour();

```
### Запрет на создание пустых постов
```sql
CREATE OR REPLACE FUNCTION check_post_files_on_publish()
RETURNS TRIGGER AS $$
DECLARE
    file_count INTEGER := 0;
BEGIN
    IF NEW.status = 'published' THEN
        IF TG_OP = 'UPDATE' THEN
            SELECT COUNT(*) INTO file_count FROM post_files WHERE post_id = NEW.id;
        END IF;        
        IF file_count = 0 AND (NEW.description IS NULL OR LENGTH(TRIM(NEW.description)) = 0) THEN
            RAISE EXCEPTION 'Cannot publish an empty post (no files and empty description)';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_check_empty_post_on_insert
BEFORE INSERT ON posts
FOR EACH ROW
EXECUTE FUNCTION check_post_files_on_publish();

CREATE TRIGGER trg_check_empty_post_on_update
BEFORE UPDATE ON posts
FOR EACH ROW
EXECUTE FUNCTION check_post_files_on_publish();
```
### Запрет на удаление файлов, если пост таким образом окажется пуст
```sql
CREATE OR REPLACE FUNCTION check_post_files_on_delete()
RETURNS TRIGGER AS $$
DECLARE
    post_status TEXT;
    remaining_files INTEGER;
BEGIN
    SELECT status INTO post_status FROM posts WHERE id = OLD.post_id;
    
    IF post_status = 'published' THEN
        SELECT COUNT(*) INTO remaining_files 
        FROM post_files 
        WHERE post_id = OLD.post_id AND file_id != OLD.file_id;
        
        IF remaining_files = 0 THEN
            PERFORM 1 FROM posts 
            WHERE id = OLD.post_id 
            AND description IS NOT NULL 
            AND LENGTH(TRIM(description)) > 0;
            
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Cannot delete last file from published post without description';
            END IF;
        END IF;
    END IF;
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_post_files_on_delete
BEFORE DELETE ON post_files
FOR EACH ROW
EXECUTE FUNCTION check_post_files_on_delete();
```
---
## Функции 
### Автоматическое добавление хештегов
```sql
CREATE OR REPLACE FUNCTION process_post_hashtags(
    p_post_id BIGINT,
    p_description TEXT
) RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    tag TEXT;
    tag_id BIGINT;
    matches TEXT[];
BEGIN
    DELETE FROM post_hashtags WHERE post_id = p_post_id;

    IF p_description IS NULL THEN
        RETURN;
    END IF;

    FOR matches IN SELECT REGEXP_MATCHES(p_description, '#([a-zA-Z0-9_]+)', 'g')
    LOOP
        tag := LOWER(matches[1]);
        
        INSERT INTO hashtags (slug)
        VALUES (tag)
        ON CONFLICT (slug) DO NOTHING;

        SELECT id INTO tag_id FROM hashtags WHERE slug = tag;

        INSERT INTO post_hashtags (post_id, hashtag_id)
        VALUES (p_post_id, tag_id)
        ON CONFLICT DO NOTHING;
    END LOOP;
END;
$$;
```
### Архивирование постов заблокированных пользователей
```sql
CREATE OR REPLACE PROCEDURE ban_user_and_archive_posts(
    p_user_id BIGINT
) LANGUAGE plpgsql AS $$
BEGIN
    UPDATE users 
    SET status = 'banned',
        updated_at = NOW()
    WHERE id = p_user_id
    AND status = 'active';
    
    UPDATE posts 
    SET status = 'archived',
        updated_at = NOW()
    WHERE user_id = p_user_id
    AND status = 'published';
END;
$$;
```
### Пользователь может использовать в качестве аватара только файл типа image
```sql
CREATE OR REPLACE FUNCTION set_user_avatar(
    p_user_id BIGINT,
    p_file_id BIGINT
) RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    v_file_type VARCHAR(50);
    v_current_avatar_id BIGINT;
BEGIN
    SELECT type INTO v_file_type FROM files WHERE id = p_file_id;
    
    IF v_file_type <> 'image' THEN
        RAISE EXCEPTION 'File must be image, not %', v_file_type;
    END IF;
    
    UPDATE users SET (avatar_id, updated_at) = (p_file_id, NOW()) WHERE id = p_user_id;
END;
$$;
```
---
## Транзакции
### Попытка создать пустой пост
```sql
BEGIN;

INSERT INTO posts (user_id, description, status) 
VALUES (1, NULL, 'published')
RETURNING id INTO post_id;

COMMIT;
```
### Блокировка пользователя с архивированием постов
```sql
BEGIN;

SELECT id FROM users WHERE id = 2 AND status = 'active' FOR UPDATE;

CALL ban_user_and_archive_posts(2);

COMMIT;
```
### Установка аватара
```sql
BEGIN;

DO $$
BEGIN
    PERFORM set_user_avatar(1, 4);
EXCEPTION WHEN OTHERS THEN
    RAISE EXCEPTION 'Failed to set user avatar: %', SQLERRM;
END $$;

COMMIT;
```
---
## Индексы
Наиболее частые операции:
- **Получение постов**: получение данных posts с фильтрацией по user_id, status, created_at
- **Поиск по хештегам**: Соединение таблиц hashtags, post_hashtags
- **Добавление новых постов**: вставка в таблицу posts, hashtags, post_files, post_hashtags
- **Получение файлов**: получение файлов с фильтрацией по type
- **Получение файлов по post_id**
```sql
CREATE INDEX idx_files_type ON files(type);
CREATE INDEX idx_posts_user_status_created ON posts(user_id, status, created_at DESC);
CREATE INDEX idx_post_files_post_id ON post_files(post_id);
CREATE INDEX idx_post_hashtags_hashtag_id ON post_hashtags(hashtag_id);
```

