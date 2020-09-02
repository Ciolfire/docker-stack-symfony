CREATE DATABASE IF NOT EXISTS kannel_database;

CREATE USER IF NOT EXISTS 'kannel_user'@'%' IDENTIFIED BY 'kannel_password';
GRANT ALL PRIVILEGES ON kannel_database.* TO 'kannel_user'@'%';
FLUSH PRIVILEGES;