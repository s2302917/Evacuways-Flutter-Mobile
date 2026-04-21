<?php
require_once '../config/headers.php';
require_once '../config/database.php';

try {
    $database = new Database();
    $db = $database->connect();

    // Fetch all pending SOS requests from ALL users
    $query = "SELECT r.*, CONCAT(u.first_name, ' ', u.last_name) as user_name 
              FROM evacuways_support_requests r
              JOIN evacuways_users u ON r.user_id = u.user_id
              WHERE r.status = 'Pending' 
              AND r.latitude IS NOT NULL 
              AND r.longitude IS NOT NULL
              ORDER BY r.created_at DESC";

    $stmt = $db->prepare($query);
    $stmt->execute();

    $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);

    http_response_code(200);
    echo json_encode(["success" => true, "requests" => $requests]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
}
?>
