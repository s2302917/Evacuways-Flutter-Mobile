<?php
require_once '../config/headers.php';
require_once '../config/database.php';

try {
    $database = new Database();
    $db = $database->connect();

    // Check if column exists
    $checkQuery = "SHOW COLUMNS FROM evacuways_messages LIKE 'is_read'";
    $stmt = $db->query($checkQuery);
    $columnExists = $stmt->fetch();

    if (!$columnExists) {
        // Add the column
        $alterQuery = "ALTER TABLE evacuways_messages ADD COLUMN is_read TINYINT(1) DEFAULT 0";
        $db->exec($alterQuery);
        $messages[] = "Column 'is_read' added.";
    }

    $checkQuery = "SHOW COLUMNS FROM evacuways_messages LIKE 'deleted_by_sender'";
    $stmt = $db->query($checkQuery);
    if (!$stmt->fetch()) {
        $db->exec("ALTER TABLE evacuways_messages ADD COLUMN deleted_by_sender TINYINT(1) DEFAULT 0");
        $messages[] = "Column 'deleted_by_sender' added.";
    }

    $checkQuery = "SHOW COLUMNS FROM evacuways_messages LIKE 'deleted_by_receiver'";
    $stmt = $db->query($checkQuery);
    if (!$stmt->fetch()) {
        $db->exec("ALTER TABLE evacuways_messages ADD COLUMN deleted_by_receiver TINYINT(1) DEFAULT 0");
        $messages[] = "Column 'deleted_by_receiver' added.";
    }

    if (empty($messages)) {
        echo json_encode([
            "success" => true,
            "message" => "Database is already up to date. All columns exist."
        ]);
    } else {
        echo json_encode([
            "success" => true,
            "message" => "Database updated successfully: " . implode(" ", $messages)
        ]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        "success" => false, 
        "message" => "Database error: " . $e->getMessage()
    ]);
}
?>
