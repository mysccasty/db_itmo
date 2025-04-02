# Лабораторная работа 3
### Выполнил:
* Кузнецов Владимир
* Группа P4150
* Дата выполнения: 27.03.2025
* Наименование дисциплины: Взаимодействие с базами данных

## Текст задания
1.  Реализованную в рамках лабораторной работы №2 даталогическую модель привести в 3 нормальную форму. Если в вашей предметной области эффективнее использовать денормализованную модель – это нужно обосновать при сдаче ЛР. 
2.  Привести 3 примера анализа функциональной зависимости атрибутов. Соответственно, для трех таблиц (в предметной области каждого студента должно быть не менее трех таблиц). 
3.  Обеспечить целостность данных таблиц при помощи средств языка DDL. Задача – это продемонстрировать знание видов ограничений целостности. Чем больше будет использовано, тем меньше вопросов будет задано. 
4.  Заполнить таблицы данными
5.  В рамках лабораторной работы должны быть разработаны скрипты-примеры для создания/удаления требуемых объектов базы данных, заполнения/удаления содержимого созданных таблиц. Студент должен быть готов продемонстрировать работу скриптов!
6.  Составить 6+3 примеров SQL запросов на объединение таблиц предметной области. Студент должен быть готов продемонстрировать работу запросов и обосновать их результаты, почему они получились именно такими. 6 – это INNER, FULL, LEFT, RIGTH, CROSS, OUTER и еще 3 JOIN ON, JOIN USING, NATURAL JOIN
## Предметная область
Система управления пользовательским контентом
## Даталогическая модель
![ER-диаграмма](../lab2/er.png)
## Приведение к 3 нормальной форме
Отношения в даталогической модели находятся в 1 нф, так атрибуты отношений имеют атомарные значения.  
Отношения находятся во 2 нф, так как отсутствуют частичные функциональные зависимости от ключей.  
Все отношения за исключением files находятся в 3 нф, так как нет транзитивных зависимостей от ключа.  
Атрибут type в отношении files зависит от filename, определяется значением расширения в имени.  
Если расширения нет, то type ставится 'document'
Для приведения в 3нф необходимо разделить таблицы
```sql
CREATE TABLE file_types (
    extension VARCHAR(10) PRIMARY KEY,
    type VARCHAR(20) NOT NULL
);
CREATE TABLE files (
    id BIGSERIAL PRIMARY KEY,
    filename VARCHAR(255) NOT NULL,
    extension VARCHAR(10),
    path VARCHAR(255) NOT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (extension) REFERENCES file_types(extension)
);
```
Запросы на вставку и селект будет выглядеть так
```sql
INSERT INTO file_types (extension, type) VALUES
('pdf', 'document'),
('jpg', 'image');

INSERT INTO files (filename, extension, path) VALUES
('abc', 'pdf','/'),
('def', 'jpg','/'),
('ReadMe', NULL, '');
SELECT 
    f.id,
    f.filename,
    COALESCE(ft.type, 'document') AS type
FROM files f
LEFT JOIN file_types ft ON f.extension = ft.extension;
```
Однако необходимо для каждого нового файла перед добавлением проверять, есть ли соответсвующее расширение, чтобы не нарушать целостность.  
Так как filename, extension, type практически всегда требуются вместе, то стоит оставить отношение files в денормализованной форме.  
## Анализ функциональной зависимости
Рассмотрим функциональные зависимости для каждой таблицы, сохраняя денормализованную структуру (без приведения к 3NF).

---

### **1. Отношение `Пользователи`**
**Функциональные зависимости:**
1. **Основные зависимости от PK:**
   - `id → {username, email, phone, password_hash, first_name, last_name, status, created_at, updated_at, avatar_id}`  
     (Все атрибуты функционально зависят от первичного ключа `id`)

2. **Обратные уникальные зависимости:**
   - `username → id` (`username` уникален)
   - `email → id` (Уникальный email однозначно идентифицирует пользователя)
   - `phone → id` (Уникальный телефон определяет пользователя)

---

### **2. Отношение `Файлы` (денормализованная)**
**Функциональные зависимости:**
1. **Основные зависимости от PK:**
   - `id → {type, path, filename, uploaded_at}`  

2. Транзитивная зависимость: `id → filename → type`
---

### **3. Таблица `Посты`**

**Функциональные зависимости:**
1. **Основные зависимости от PK:**
   - `id → {user_id, description, status, created_at, updated_at}`

### **4. Таблица `Хэштеги`**

**Функциональные зависимости:**
1. **Основные зависимости от PK:**
   - `id → {slug}`
## Целостность таблицы
Можно добавить дополнительные проверки полей
```sql
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
```
[Создание объектов бд](create_object.sql)  
[Удаление объектов бд](delete_object.sql)  
[Заполнение таблиц](insert_data.sql)  
[Очистка таблиц ](clear_data.sql)  
## Примеры запросов  
1. Получаем все опубликованные посты с именами их авторов
```sql
SELECT p.id as post_id, p.description, u.username
FROM posts p
INNER JOIN users u ON p.user_id = u.id
WHERE p.status = 'published';
```
2. Получаем всех пользователей и их посты(постов у некоторых пользователей может не быть)
```sql
SELECT u.username, u.email, p.id AS post_id, p.description
FROM users u
LEFT JOIN posts p ON u.id = p.user_id;
```
3. Найти все файлы, которые не прикреплены к постам
```sql
SELECT 
    f.id as file_id,
    f.filename,
    f.uploaded_at
FROM 
    post_files pf
RIGHT JOIN 
    files f ON pf.file_id = f.id
WHERE 
    pf.post_id IS NULL;
```
4. Получаем все хэштеги и все посты, с их связями
```sql
SELECT h.slug, p.id, p.description
FROM hashtags h
FULL OUTER JOIN post_hashtags ph ON h.id = ph.hashtag_id
FULL OUTER JOIN posts p ON ph.post_id = p.id;
```
5. Все возможные комбинации пользователей и типов файлов
```sql
SELECT u.username, f.type AS file_type
FROM users u
CROSS JOIN (SELECT DISTINCT type FROM files) f;
```
6. Посты с хэштегами, созданные активными пользователями
```sql
SELECT p.id, p.description, h.slug, u.username
FROM posts p
JOIN post_hashtags ph ON p.id = ph.post_id
JOIN hashtags h ON ph.hashtag_id = h.id
JOIN users u ON p.user_id = u.id AND u.status = 'active';
```
7. Связи постов и файлов  
Предварительно переименуем атрибуты в posts и files:
```sql
ALTER TABLE posts
RENAME COLUMN id TO post_id;
ALTER TABLE files
RENAME COLUMN id TO file_id;
```
```sql
SELECT p.post_id, p.description, f.filename
FROM post_files
JOIN posts p USING(post_id)
JOIN files f USING(file_id);
```
8. Автоматическое соединение таблицы post_hashtags с hashtags  
Аналогично переименуем:
```sql
ALTER TABLE hashtags
RENAME COLUMN id TO hashtag_id;
```
```sql
SELECT ph.post_id, h.slug
FROM post_hashtags ph
NATURAL JOIN hashtags h;
```
9. Получение наиболее популярных хэштегов по количеству постов
```sql
SELECT
    h.slug AS hashtag,
    COUNT(DISTINCT ph.post_id) AS post_count
FROM
    hashtags h
LEFT JOIN
    post_hashtags ph ON h.id = ph.hashtag_id
LEFT JOIN
    posts p ON ph.post_id = p.post_id
GROUP BY
    h.slug
ORDER BY
    post_count DESC
```