<?php
require_once '../config/headers.php';
require_once '../config/database.php';

try {
    $database = new Database();
    $db = $database->connect();

    // Check if columns exist
    $table = "evacuways_support_requests";
    $columnsToAdd = [
        "latitude" => "DECIMAL(10, 8) NULL",
        "longitude" => "DECIMAL(11, 8) NULL"
    ];

    $existingColumns = $db->query("DESCRIBE $table")->fetchAll(PDO::FETCH_COLUMN);

    foreach ($columnsToAdd as $col => $definition) {
        if (!in_array($col, $existingColumns)) {
            $db->exec("ALTER TABLE $table ADD COLUMN $col $definition");
            echo "Column '$col' added successfully.<br>";
        } else {
            echo "Column '$col' already exists.<br>";
        }
    }

    echo "Migration completed successfully.";

} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}
?>
