<?php
header('Content-Type: application/json');
require_once '../config/headers.php';
require_once '../config/database.php';

// POST leave_family.php - User leaves family
try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $family_id = isset($input['family_id']) ? intval($input['family_id']) : null;
    $user_id = isset($input['user_id']) ? intval($input['user_id']) : null;
    
    if (!$family_id || !$user_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing required fields']);
        exit();
    }
    
    $database = new Database();
    $conn = $database->connect();
    
    if (!$conn) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database connection failed']);
        exit();
    }
    
    // Remove user from family
    $query = "UPDATE evacuways_users SET family_id = NULL WHERE user_id = :user_id AND family_id = :family_id";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
    $stmt->bindParam(':family_id', $family_id);
    $stmt->execute();
    
    if ($stmt->rowCount() > 0) {
        http_response_code(200);
        echo json_encode(['success' => true, 'message' => 'Left family successfully']);
    } else {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Failed to leave family']);
    }
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>
