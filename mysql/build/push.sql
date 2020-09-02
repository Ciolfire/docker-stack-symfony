CREATE DATABASE IF NOT EXISTS push_database;

CREATE USER IF NOT EXISTS 'push_user' IDENTIFIED BY 'push_password';
GRANT ALL PRIVILEGES ON push_database.* TO 'push_user'@'%';
FLUSH PRIVILEGES;