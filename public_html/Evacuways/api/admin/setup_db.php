<?php
require_once '../config/headers.php';
require_once '../config/database.php';

try {
    $database = new Database();
    $db = $database->connect();

    echo "Starting Database Alignment...<br>";

    // 1. Add current_occupants to evacuways_vehicles if missing
    $check_col = $db->query("SHOW COLUMNS FROM evacuways_vehicles LIKE 'current_occupants'");
    if ($check_col->rowCount() == 0) {
        $db->exec("ALTER TABLE evacuways_vehicles ADD COLUMN current_occupants INT DEFAULT 0 AFTER capacity");
        echo "Added 'current_occupants' column to evacuways_vehicles.<br>";
    } else {
        echo "'current_occupants' column already exists in evacuways_vehicles.<br>";
    }

    // 2. Ensure evacuways_user_presences exists
    $db->exec("CREATE TABLE IF NOT EXISTS evacuways_user_presences (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        resource_type ENUM('center', 'vehicle') NOT NULL,
        resource_id INT NOT NULL,
        headcount INT DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY user_presence (user_id)
    )");
    echo "Ensured 'evacuways_user_presences' table exists.<br>";

    // 3. Warm up Coordinates (NULL -> Sample Iloilo/Bacolod area near Admin)
    // Admin 1 is at 10.6797237, 122.9605826 (Villamonte)
    $base_lat = 10.6797237;
    $base_lng = 122.9605826;

    // Update Center 1 (St. Vincent High School)
    $db->prepare("UPDATE evacuways_centers SET latitude = :lat, longitude = :lng WHERE center_id = 1 AND latitude IS NULL")
       ->execute([':lat' => $base_lat + 0.002, ':lng' => $base_lng + 0.003]);
    
    // Update Vehicle 1 (Ambulance - Taculing)
    $db->prepare("UPDATE evacuways_vehicles SET latitude = :lat, longitude = :lng WHERE vehicle_id = 1 AND latitude IS NULL")
       ->execute([':lat' => $base_lat - 0.005, ':lng' => $base_lng - 0.004]);

    // Update Vehicle 2 (Bus - Granada)
    $db->prepare("UPDATE evacuways_vehicles SET latitude = :lat, longitude = :lng WHERE vehicle_id = 2 AND latitude IS NULL")
       ->execute([':lat' => $base_lat + 0.008, ':lng' => $base_lng + 0.008]);

    echo "Updated NULL coordinates for Centers and Vehicles with sample map data.<br>";

    echo "<strong>Alignment Complete!</strong><br>";
    echo "You can now check the Map in the app to see the resources.";

} catch (PDOException $e) {
    echo "Error during alignment: " . $e->getMessage();
}
?>
