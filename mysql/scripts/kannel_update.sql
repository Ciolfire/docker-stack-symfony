
-- SET GLOBAL log_bin_trust_function_creators = 1;

USE kannel_database;

-- ===== TABLES =====
-- Note that for each table and trigger we first DROP the ancient one to allow the creation of the new one, please keep that into mind when updating

-- Table to store the receiver answers
DROP TABLE IF EXISTS kannel_response;
CREATE TABLE kannel_response (
  id int(11) NOT NULL,
  sending_id int(11) DEFAULT NULL,
  number_id int(11) DEFAULT NULL,
  msisdn varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  received_at datetime NOT NULL,
  response varchar(160) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
ALTER TABLE kannel_response ADD PRIMARY KEY (id);
ALTER TABLE kannel_response MODIFY id int(11) NOT NULL AUTO_INCREMENT;
SET FOREIGN_KEY_CHECKS=1;

-- Main table to create the communication between the push and Kannel
DROP TABLE IF EXISTS snd;
CREATE TABLE `kannel_database`.`snd` (
  `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT 'Every message has a unique id' ,
  `sending_id` INT NOT NULL COMMENT 'Sending associated to the message' ,
  `number_id` INT NOT NULL COMMENT 'affiliated id in the push app' ,
  `sender` VARCHAR(20) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL COMMENT 'Name of the sender' ,
  `receiver` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL COMMENT 'Receiving number' ,
  `msg` LONGTEXT CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL COMMENT 'Body of the message to send' ,
  `smsc_id` VARCHAR(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NULL COMMENT 'Identifier of the target SMSC' ,
  `sent_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Theorical sending date' ,
  `status` INT NOT NULL DEFAULT '0' COMMENT '1: Delivered to phone, 2: Non-delivered to phone, 4: Queued on SMSC, 8: Delivered to SMSC, 16: Non-delivered to SMSC.' ,
  `updated_at` DATETIME NULL COMMENT 'Last status date' ,
  PRIMARY KEY (`id`)
  ) CHARSET=utf8 COLLATE utf8_unicode_ci COMMENT='This table holds the messages that are sent, including DLR values.'; 

-- ===== TRIGGERS =====
-- The following trigger inserts appropriate values into the send_sms table. Kannel scans this table and send out any message that is entered, subsequently deleting it.
-- Our message keeps being held in the ‘snd’ table. We keep a reference to our record in `snd` by inserting `snd.id` in the dlr_url place holder.

-- first, we drop the triggers if it exists already, in case we are updating
DROP TRIGGER IF EXISTS after_snd_insert;
DROP TRIGGER IF EXISTS after_sent_sms_insert;
DROP TRIGGER IF EXISTS set_sender_id;

DELIMITER //
-- This trigger is set when we add a new message to be sent in snd
CREATE TRIGGER after_snd_insert
AFTER INSERT ON snd 
FOR EACH ROW
BEGIN
  INSERT INTO send_sms (momt, sender, receiver, msgdata, time, smsc_id, sms_type, coding, deferred, dlr_mask, dlr_url) 
  VALUES ('MT', NEW.sender, CONCAT('+', NEW.receiver), NEW.msg, UNIX_TIMESTAMP(), NEW.smsc_id, 2, 0, TIMESTAMPDIFF(MINUTE, CURRENT_TIMESTAMP, NEW.sent_at), 63, NEW.id);
END;//

-- This trigger is set when a message has been sent and update the status
CREATE TRIGGER after_sent_sms_insert
AFTER INSERT ON sent_sms 
FOR EACH ROW BEGIN
  IF NEW.momt = 'DLR' THEN
    UPDATE snd SET status = NEW.dlr_mask, updated_at = FROM_UNIXTIME(NEW.time) WHERE id = NEW.dlr_url;
  ELSEIF NEW.momt = 'MO' THEN
    INSERT INTO kannel_response (sending_id, msisdn, received_at, response) VALUES (NULL, REPLACE(NEW.sender, '+', ''), NOW(), NEW.msgdata);
  END IF;
END;//

-- This trigger set the sending_id in the response table of kannel to better visualize the flow of the messages
DELIMITER //
CREATE TRIGGER set_sender_id
BEFORE INSERT ON kannel_response
FOR EACH ROW
  BEGIN
    SET NEW.sending_id = (SELECT sending_id FROM `snd` WHERE snd.receiver = NEW.msisdn ORDER BY id DESC LIMIT 1);
    SET NEW.number_id = (SELECT number_id FROM `snd` WHERE snd.receiver = NEW.msisdn ORDER BY id DESC LIMIT 1);
  END//
DELIMITER ;



-- ===== UNKNOW TABLES =====

-- I have no idea what this table is used for...
-- DROP TABLE IF EXISTS dlr;
-- CREATE TABLE dlr (
--   smsc varchar(40) DEFAULT NULL,
--   ts varchar(40) DEFAULT NULL,
--   destination varchar(40) DEFAULT NULL,
--   source varchar(40) DEFAULT NULL,
--   service varchar(40) DEFAULT NULL,
--   url varchar(255) DEFAULT NULL,
--   mask int(10) DEFAULT NULL,
--   status int(10) DEFAULT NULL,
--   boxc varchar(40) DEFAULT NULL
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- -- Archive table ..?
-- DROP TABLE IF EXISTS sent_sms_save_mo;
-- CREATE TABLE sent_sms_save_mo LIKE sent_sms;
-- ALTER TABLE sent_sms_save_mo CHANGE sql_id sql_id BIGINT(20) UNSIGNED NOT NULL;