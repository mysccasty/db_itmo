# Лабораторная работа 1
### Выполнил:
* Кузнецов Владимир
* Группа P4150
* Дата выполнения: 13.03.2025
* Наименование дисциплины: Взаимодействие с базами данных

## Текст задания
Необходимо составить подробное текстовое описание предметной области. Описание должно четко задавать границы домена: указаны участвующие в процессах домена сущности, должны быть описаны характеристики сущностей и показаны отношения между сущностями (как сущности взаимодействуют и влияют друг на друга).
## Описание предметной области

**Предметная область:** Покупка/продажа контента пользователями  

**Границы домена:**  
Предметная область охватывает процессы, связанные с созданием, отображением, продажей и покупкой цифрового контента между пользователями. Включает в себя управление контентом, учет транзакций.  

**Сущности и их характеристики:**  

1. **Пользователь**  
   - ID пользователя(уникальный)
   - Никнейм / логин
   - Почта
   - Номер телефона
   - Хэш пароля
   - Имя
   - Фамилия
   - Статус 
   - Тип пользователя
   - Дата регистрации
   - Дата обновления

2. **Контент**  
   - UUID контента
   - ID пользователя-продавца
   - ID категории
   - Название контента
   - Описание контента
   - Цена
   - Статус
   - Дата создания
   - Дата обновления

3. **Транзакция**  
   - UUID транзакции
   - ID покупателя
   - ID контента
   - Сумма транзакции
   - Сумма рефанда
   - Сумма чаржбека
   - Дата транзакции
   - Дата рефанда
   - Дата чаржбека
   - Статус транзакции

4. **Категория контента**  
   - ID категории(уникальный)
   - Название категории
   - Слаг
   - Описание категории

5. **Файл**
   - ID файла(уникальный)
   - Тип
   - Путь к файлу
   - Имя файла
   - Дата загрузки
   - ID родительского файла

6. **Связь файла и контента**
   - ID
   - ID файла
   - ID контента

7. **Связь файла и транзакции**
   - ID
   - ID файла
   - ID транзакции




**Отношения между сущностями:**  

**Пользователь и Контент:**  
Один пользователь (продавец) может создавать множество контентов.
Один контент принадлежит одному продавцу
Связь: один ко многим

**Пользователь и Транзакция:**  
Один пользователь (покупатель) может иметь множество транзакций.
Одна транзакция связана с одним пользователем-покупателем.  
Связь: один ко многим.  

**Контент и Транзакция:**  
Один контент может быть продан множество раз.  
Одна транзакция связана с одним контентом.  
Связь: один ко многим.  

**Контент и Категория:**  
Один контент принадлежит к одной категории.  
Одна категория может включать множество контентов.  
Связь: один ко многим.

**Файл и Контент:**
Один контент может иметь несколько файлов.
Один файл может принадлежать нескольким файлам.
Связь: многие ко многим

**Файл и Транзакция:**
Связь: многие ко многим


**Процессы в домене:**  
- Регистрация новых пользователей (продавцов и покупателей).  
- Создание и публикация контента продавцами.
- Отображение пользователю контента в соответствующих категориях и с заблюренными файлами
- Покупка контента покупателями и возврат средств.
- Предоставление доступа покупателю к файлам контента


---