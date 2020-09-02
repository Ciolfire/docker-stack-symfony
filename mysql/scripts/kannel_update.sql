
-- SET GLOBAL log_bin_trust_function_creators = 1;

USE kannel_database;

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

-- first, we drop the triggers if it exists already, in case we are updating
DROP TRIGGER IF EXISTS after_snd_insert;
DROP TRIGGER IF EXISTS after_sent_sms_insert;

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

DELIMITER ;
