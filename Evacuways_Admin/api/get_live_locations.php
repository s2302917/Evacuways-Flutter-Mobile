<?php
header('Content-Type: application/json');

// We add an extra "/.." because we are now inside the "api" folder 
// and need to go up one level to find "app"
require_once __DIR__ . "/../app/config/database.php";

try {
    $database = new Database();
    $db = $database->connect();

    $sql = "SELECT latitude, longitude, timestamp 
            FROM evacuways_user_locations 
            WHERE timestamp > (NOW() - INTERVAL 5 MINUTE)
            ORDER BY timestamp DESC LIMIT 100";

    $stmt = $db->prepare($sql);
    $stmt->execute();
    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));

} catch (PDOException $e) {
    echo json_encode([]);
}