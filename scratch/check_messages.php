<?php
require_once 'e:/flutter_projects/evacuways/Evacuways_Admin/app/config/database.php';

$database = new Database();
$db = $database->connect();

$stmt = $db->query("SELECT * FROM evacuways_messages WHERE image_path IS NOT NULL ORDER BY sent_at DESC LIMIT 10");
$messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Last 10 messages with images:\n";
foreach ($messages as $m) {
    echo "ID: " . $m['message_id'] . " | Sender: " . $m['sender_type'] . " | Path: " . $m['image_path'] . " | At: " . $m['sent_at'] . "\n";
}
?>
