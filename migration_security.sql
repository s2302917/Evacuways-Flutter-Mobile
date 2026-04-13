-- Migration to support automated account creation and forced password change
ALTER TABLE `evacuways_users` 
ADD COLUMN `must_change_password` TINYINT(1) DEFAULT 0 AFTER `password_hash`;

-- Ensure contact_number is unique for login purposes
ALTER TABLE `evacuways_users` 
ADD UNIQUE INDEX `idx_contact_number` (`contact_number`);
