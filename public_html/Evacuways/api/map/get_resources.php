<?php
require_once '../config/headers.php';
require_once '../config/database.php';

try {
    $database = new Database();
    $conn = $database->connect();
    
    if ($conn === null) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database connection failed!"]);
        exit();
    }

    // --- AUTO-ALIGNMENT BLOCK ---
    // 1. Ensure current_occupants exists in vehicles
    $check_col = $conn->query("SHOW COLUMNS FROM evacuways_vehicles LIKE 'current_occupants'");
    if ($check_col->rowCount() == 0) {
        $conn->exec("ALTER TABLE evacuways_vehicles ADD COLUMN current_occupants INT DEFAULT 0 AFTER capacity");
    }

    // 2. Warm up NULL Coordinates near Admin 1 (10.6797237, 122.9605826)
    $base_lat = 10.6797237;
    $base_lng = 122.9605826;
    
    // Update Centers with prepared statements
    $update_centers = "UPDATE evacuways_centers SET latitude = :lat1, longitude = :lng1 WHERE latitude IS NULL";
    $stmt = $conn->prepare($update_centers);
    $stmt->bindParam(':lat1', $base_lat);
    $stmt->bindParam(':lng1', $base_lng);
    $stmt->execute();
    
    // Update Vehicles with prepared statements
    $update_v1 = "UPDATE evacuways_vehicles SET latitude = :lat2, longitude = :lng2 WHERE vehicle_id = 1 AND latitude IS NULL";
    $stmt = $conn->prepare($update_v1);
    $lat2 = $base_lat - 0.005;
    $lng2 = $base_lng - 0.004;
    $stmt->bindParam(':lat2', $lat2);
    $stmt->bindParam(':lng2', $lng2);
    $stmt->execute();
    
    $update_v2 = "UPDATE evacuways_vehicles SET latitude = :lat3, longitude = :lng3 WHERE vehicle_id = 2 AND latitude IS NULL";
    $stmt = $conn->prepare($update_v2);
    $lat3 = $base_lat + 0.008;
    $lng3 = $base_lng + 0.008;
    $stmt->bindParam(':lat3', $lat3);
    $stmt->bindParam(':lng3', $lng3);
    $stmt->execute();
    // --- END AUTO-ALIGNMENT ---

    // Fetch Admin Headquarters
    $admins_query = "SELECT admin_id, full_name, role, latitude, longitude 
                     FROM evacuways_admins 
                     WHERE latitude IS NOT NULL AND longitude IS NOT NULL";
    $admins_stmt = $conn->prepare($admins_query);
    $admins_stmt->execute();
    $admins = $admins_stmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch active evacuation centers
    $centers_query = "SELECT center_id, center_name, barangay_name, capacity, current_individuals, status, contact_person, contact_number, latitude, longitude 
                      FROM evacuways_centers";
    $centers_stmt = $conn->prepare($centers_query);
    $centers_stmt->execute();
    $centers = $centers_stmt->fetchAll(PDO::FETCH_ASSOC);

    // Fetch active rescue vehicles
    $vehicles_query = "SELECT vehicle_id, vehicle_type, plate_number, capacity, current_occupants, status, driver_name, driver_contact, landmark, latitude, longitude 
                       FROM evacuways_vehicles";
    $vehicles_stmt = $conn->prepare($vehicles_query);
    $vehicles_stmt->execute();
    $vehicles = $vehicles_stmt->fetchAll(PDO::FETCH_ASSOC);

    // If data is lacking coordinates, or lists are empty, add descriptive fallbacks
    if (empty($admins) && empty($centers) && empty($vehicles)) {
        // Absolute fallback for completely empty DB
        $base_lat = 10.6797237; 
        $base_lng = 122.9605826;
        $admins = [[
            "admin_id" => "0",
            "full_name" => "System Admin (Default)",
            "role" => "System",
            "latitude" => $base_lat,
            "longitude" => $base_lng
        ]];
    }

    http_response_code(200);
    echo json_encode([
        "success" => true,
        "admins" => $admins,
        "centers" => $centers,
        "vehicles" => $vehicles
    ]);

} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "System error: " . $e->getMessage()]);
}
?>
