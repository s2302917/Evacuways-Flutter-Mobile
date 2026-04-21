<?php
require_once 'e:/flutter_projects/evacuways/public_html/Evacuways/api/config/database.php';
$database = new Database();
$db = $database->connect();
$db->exec("ALTER TABLE evacuways_messages ADD COLUMN IF NOT EXISTS is_read TINYINT(1) DEFAULT 0");
echo "Column is_read added successfully or already exists.";
?>
