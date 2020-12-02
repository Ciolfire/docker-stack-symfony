CREATE DATABASE IF NOT EXISTS kannel_database;
CREATE DATABASE IF NOT EXISTS kannel_database_test;

CREATE USER IF NOT EXISTS 'kannel_user'@'%' IDENTIFIED BY 'kannel_password';
GRANT ALL PRIVILEGES ON kannel_database.* TO 'kannel_user'@'%';
GRANT ALL PRIVILEGES ON kannel_database_test.* TO 'kannel_user'@'%';
FLUSH PRIVILEGES;