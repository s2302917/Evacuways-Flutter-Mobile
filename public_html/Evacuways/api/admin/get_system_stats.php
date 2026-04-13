<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_system_stats.php - Get system statistics
try {
    $database = new Database();
    $conn = $database->connect();
    
    $stats = [];
    
    // Total users
    $query = "SELECT COUNT(*) as total FROM evacuways_users";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $stats['total_users'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Active rescue operations
    $query = "SELECT COUNT(*) as total FROM evacuways_users WHERE rescue_status = 'Pending Rescue' OR rescue_status = 'In Transit'";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $stats['active_rescue_operations'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Total vehicles
    $query = "SELECT COUNT(*) as total FROM evacuways_vehicles";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $stats['total_vehicles'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Available vehicles
    $query = "SELECT COUNT(*) as total FROM evacuways_vehicles WHERE status = 'Standby'";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $stats['available_vehicles'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Total evacuation centers
    $query = "SELECT COUNT(*) as total FROM evacuways_centers";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $stats['total_centers'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Total occupancy
    $query = "SELECT SUM(current_individuals) as total FROM evacuways_centers";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $stats['total_occupancy'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'] ?? 0;
    
    // Active alerts
    $query = "SELECT COUNT(*) as total FROM evacuways_alerts WHERE status = 'Active'";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $stats['active_alerts'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Pending support requests
    $query = "SELECT COUNT(*) as total FROM evacuways_support_requests WHERE status = 'Pending'";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $stats['pending_support_requests'] = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    http_response_code(200);
    echo json_encode($stats);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
