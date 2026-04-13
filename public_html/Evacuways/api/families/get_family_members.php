<?php
header('Content-Type: application/json');
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_family_members.php - Get all members of a family
try {
    $family_id = isset($_GET['family_id']) ? intval($_GET['family_id']) : null;
    
    if (!$family_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Family ID is required']);
        exit();
    }
    
    $database = new Database();
    $conn = $database->connect();
    
    if (!$conn) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database connection failed']);
        exit();
    }
    
    // Get all family members with their details
    $query = "SELECT u.user_id, u.first_name, u.last_name, u.contact_number, 
                     u.rescue_status, u.missing_count, u.gender, u.birth_date
              FROM evacuways_users u
              WHERE u.family_id = :family_id
              ORDER BY u.created_at ASC";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':family_id', $family_id);
    $stmt->execute();
    
    $members = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    http_response_code(200);
    echo json_encode($members);
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>
