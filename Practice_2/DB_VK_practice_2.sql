
-- Создаем базу --
DROP DATABASE IF EXISTS vk;
CREATE DATABASE vk;
USE vk;

-- добавляем таблицы --
DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, -- id ЧИСЛО ПОЛОЖИТЕЛЬНОЕ НЕ ПУСТОЕ АВТО_УВЕЛИЧЕНИЕ ПЕРВИЧНЫЙ КЛЮЧ
    firstname VARCHAR(50),
    lastname VARCHAR(50) COMMENT 'Фамилия', -- COMMENT на случай, если имя неочевидное
    email VARCHAR(120) UNIQUE,
 	password_hash VARCHAR(100), -- 123456 => vzx;clvgkajrpo9udfxvsldkrn24l5456345t
	phone BIGINT UNSIGNED UNIQUE, 
	
    INDEX users_firstname_lastname_idx(firstname, lastname)
) COMMENT 'юзеры';

DROP TABLE IF EXISTS `profiles`;
CREATE TABLE `profiles` (
	user_id BIGINT UNSIGNED NOT NULL PRIMARY KEY,
    gender CHAR(1),
    birthday DATE,
	photo_id BIGINT UNSIGNED NULL,
    created_at DATETIME DEFAULT NOW(), -- поле "когда пользователь зарег." тип данных DATETIME по умолчанию DEFAULT текущая дата NOW()
    hometown VARCHAR(100)
	
    -- , FOREIGN KEY (photo_id) REFERENCES media(id) -- пока рано, т.к. таблицы media еще нет
);
 -- вносим изменения в таблицу profiles --
ALTER TABLE `profiles` ADD CONSTRAINT fk_user_id -- CONSTRAINT=ОГРАНИЧЕНИЕ, fk_user_id - задаем имя ограничению
    FOREIGN KEY (user_id) REFERENCES users(id) -- добавили внешний ключ (поле(user_id)) ссылается на др.поле users(id)
    ON UPDATE CASCADE -- (значение по умолчанию) обновление - т.е обновляется главная табл.users и за ней зависимая от нее табл. profiles
    ON DELETE RESTRICT; -- (значение по умолчанию)
    
-- добавляем поле в таблицу profiles --
-- ALTER TABLE profiles ADD COLUMN birthday DATE;
-- переименовываем поле --
-- ALTER TABLE profiles RENAME COLUMN birthday TO date_of_birth; 
-- удаление поля --
-- ALTER TABLE profiles DROP COLUMN date_of_birth;

-- 1 to M -- связь 1 ко многим --
DROP TABLE IF EXISTS messages;
CREATE TABLE messages (
	id SERIAL, -- SERIAL = BIGINT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE
	from_user_id BIGINT UNSIGNED NOT NULL,
    to_user_id BIGINT UNSIGNED NOT NULL,
    body TEXT, -- тип данных TEXT подходит для больших объемов текста
    created_at DATETIME DEFAULT NOW(), 

    FOREIGN KEY (from_user_id) REFERENCES users(id), -- добавляем внешние ключи
    FOREIGN KEY (to_user_id) REFERENCES users(id)
);

 
DROP TABLE IF EXISTS friend_requests;
CREATE TABLE friend_requests (
	-- id SERIAL, -- изменили на составной первичный ключ (initiator_user_id, target_user_id)
	initiator_user_id BIGINT UNSIGNED NOT NULL,
    target_user_id BIGINT UNSIGNED NOT NULL,
    status ENUM('requested', 'approved', 'unfriended', 'declined'), -- задаем строковые константы
	requested_at DATETIME DEFAULT NOW(),
	updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP, -- NOW() и CURRENT_TIMESTAMP возвращают одно и тоже значение
	
    PRIMARY KEY (initiator_user_id, target_user_id), -- составной первичный ключ
    FOREIGN KEY (initiator_user_id) REFERENCES users(id),
    FOREIGN KEY (target_user_id) REFERENCES users(id)-- ,
    -- CHECK (initiator_user_id <> target_user_id) -- проверка инициатор не равен таргету
);
-- проверка, чтобы пользователь сам себе не отправил запрос в друзья
ALTER TABLE friend_requests 
ADD CHECK(initiator_user_id <> target_user_id); -- проверка инициатор не равен таргету
 
DROP TABLE IF EXISTS communities;
CREATE TABLE communities(
	id SERIAL,
	name VARCHAR(150),
	admin_user_id BIGINT UNSIGNED NOT NULL,
	
	INDEX communities_name_idx(name), -- индексу можно давать любое имя (communities_name_idx)
	foreign key (admin_user_id) references users(id)
);

-- M to M -- связь многие ко многим --
DROP TABLE IF EXISTS users_communities;
CREATE TABLE users_communities(
	user_id BIGINT UNSIGNED NOT NULL,
	community_id BIGINT UNSIGNED NOT NULL,
  
	PRIMARY KEY (user_id, community_id), -- чтобы не было 2 записей о пользователе и сообществе
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (community_id) REFERENCES communities(id)
);

DROP TABLE IF EXISTS media_types;
CREATE TABLE media_types(
	id SERIAL,
    name VARCHAR(255), -- 'text', 'video', 'music', 'image'
    created_at DATETIME DEFAULT NOW(),
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP
);

DROP TABLE IF EXISTS media;
CREATE TABLE media(
	id SERIAL,
    media_type_id BIGINT UNSIGNED NOT NULL,
    -- media_type ENUM ('text', 'video', 'music', 'image'),
    user_id BIGINT UNSIGNED NOT NULL,
  	body TEXT,
    filename VARCHAR(255),-- храним только путь к файлу   	
    size INT,
	metadata JSON, -- метаданные файла (когда создан, какие права и т.п.), тип данных JSON
    created_at DATETIME DEFAULT NOW(), -- дата создания медиазаписи
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (media_type_id) REFERENCES media_types(id)
);

DROP TABLE IF EXISTS likes;
CREATE TABLE likes(
	id SERIAL,
    user_id BIGINT UNSIGNED NOT NULL,
    media_id BIGINT UNSIGNED NOT NULL,
    created_at DATETIME DEFAULT NOW()

    -- PRIMARY KEY (user_id, media_id) – можно было и так вместо id в качестве PK
  	-- слишком увлекаться индексами тоже опасно, рациональнее их добавлять по мере необходимости (н-р., провисают по времени какие-то запросы)  

/* намеренно забыли, чтобы позднее увидеть их отсутствие в ER-диаграмме
    , FOREIGN KEY (user_id) REFERENCES users(id)
    , FOREIGN KEY (media_id) REFERENCES media(id)
*/
);

DROP TABLE IF EXISTS `photo_albums`;
CREATE TABLE `photo_albums` (
	`id` SERIAL,
	`name` varchar(255) DEFAULT NULL,
    `user_id` BIGINT UNSIGNED DEFAULT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
  	PRIMARY KEY (`id`)
);

DROP TABLE IF EXISTS `photos`;
CREATE TABLE `photos` (
	id SERIAL,
	`album_id` BIGINT unsigned NOT NULL,
	`media_id` BIGINT unsigned NOT NULL,

	FOREIGN KEY (album_id) REFERENCES photo_albums(id),
    FOREIGN KEY (media_id) REFERENCES media(id)
);

ALTER TABLE vk.likes 
ADD CONSTRAINT likes_fk 
FOREIGN KEY (media_id) REFERENCES vk.media(id);

ALTER TABLE vk.likes 
ADD CONSTRAINT likes_fk_1 
FOREIGN KEY (user_id) REFERENCES vk.users(id);

ALTER TABLE vk.profiles 
ADD CONSTRAINT profiles_fk_1 
FOREIGN KEY (photo_id) REFERENCES media(id);


-- ДОМАШНЕЕ ЗАДАНИЕ. Создать минимум 3 таблицы --

-- создаем таблицу игры --
DROP TABLE IF EXISTS games;
CREATE TABLE games (
	game_id SERIAL, -- задаем id 
	game_type ENUM('action', 'strategy', 'pazzle', 'racing', 'adventure'), -- задаем виды игр
	game_metadate JSON -- содержит данные игры, когда/кем создана, описание игры
);

ALTER TABLE games
ADD COLUMN num_of_users_in_game INT UNSIGNED NOT NULL; -- задали счетчик кол-ва пользователей играющих в ту или иную игру

-- создаем таблицы игр, которые сохранены у пользователя -- 
DROP TABLE IF EXISTS users_games;
CREATE TABLE users_games (
	user_id BIGINT UNSIGNED NOT NULL UNIQUE, 
	start_play DATETIME DEFAULT NOW(), -- сохраняем данные когда пользователь начал играть в ту или иную игру
	played_last_time DATETIME DEFAULT NOW(), -- сохраняем данные когда пользователь послений раз заходил в игру

FOREIGN KEY (user_id) REFERENCES games (game_id) -- пользователя связываем с игрой
);

-- создаем таблицу постов --
DROP TABLE IF EXISTS users_post; 
CREATE TABLE users_post (
	post_id SERIAL,
	post_name VARCHAR(255), -- название поста
	post_body TEXT, -- текст поста
	post_view INT UNSIGNED, -- кол-во просмотров поста
	
FOREIGN KEY (post_id) REFERENCES users (id) -- связали пост с id пользователем
);

ALTER TABLE users_post
ADD COLUMN post_like ENUM('like', 'dislike'); -- оценка поста

-- создаем таблицу комментариев к посту --
DROP TABLE IF EXISTS comments_to_users_post;
CREATE TABLE comments_to_users_post (
	comment_id SERIAL,
	comment_body TEXT, -- текст коммента
	comment_like ENUM ('like', 'dislike'), -- оценка коммента
	comment_view INT UNSIGNED, -- просмотры коммента
	comment_answer TEXT, -- ответ на комменты

FOREIGN KEY (comment_id) REFERENCES users_post (post_id) -- связываем коментарии с постом
);


