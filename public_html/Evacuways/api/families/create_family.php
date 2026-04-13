<?php
header('Content-Type: application/json; charset=UTF-8');
require_once '../config/headers.php';
require_once '../config/database.php';

// Disable output display errors to prevent JSON corruption
ini_set('display_errors', 0);
error_reporting(E_ALL);

// POST create_family.php - Create a new family group
try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid JSON input']);
        exit();
    }
    
    $family_name = isset($input['family_name']) ? trim($input['family_name']) : null;
    $primary_contact = isset($input['primary_contact']) ? trim($input['primary_contact']) : null;
    $user_id = isset($input['user_id']) ? intval($input['user_id']) : null;
    
    if (!$family_name || !$primary_contact || !$user_id) {
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
    
    // Create family
    $query = "INSERT INTO evacuways_families (family_name, primary_contact, rescue_status, created_at) 
              VALUES (:family_name, :primary_contact, :rescue_status, NOW())";
    $stmt = $conn->prepare($query);
    $stmt->bindParam(':family_name', $family_name);
    $stmt->bindParam(':primary_contact', $primary_contact);
    $rescue_status = 'Pending Rescue';
    $stmt->bindParam(':rescue_status', $rescue_status);
    
    if (!$stmt->execute()) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to create family']);
        exit();
    }
    
    $family_id = $conn->lastInsertId();
    
    if (!$family_id) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to retrieve family ID']);
        exit();
    }
    
    // Add the creator as the first member in users table
    $memberQuery = "UPDATE evacuways_users SET family_id = :family_id, is_family = 1 WHERE user_id = :user_id";
    $memberStmt = $conn->prepare($memberQuery);
    $memberStmt->bindParam(':family_id', $family_id, PDO::PARAM_INT);
    $memberStmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    
    if (!$memberStmt->execute()) {
        error_log("Failed to update creator family_id: family_id=$family_id, user_id=$user_id");
    }

    // Add the creator to family_members table as 'Head'
    $roleQuery = "INSERT INTO evacuways_family_members (family_id, user_id, role) VALUES (:family_id, :user_id, 'Head')";
    $roleStmt = $conn->prepare($roleQuery);
    $roleStmt->bindParam(':family_id', $family_id, PDO::PARAM_INT);
    $roleStmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    
    if (!$roleStmt->execute()) {
        error_log("Failed to add creator as Head in family_members: family_id=$family_id, user_id=$user_id");
    }

    // Initialize headcount to 1
    $countQuery = "UPDATE evacuways_families SET headcount = 1 WHERE family_id = :family_id";
    $countStmt = $conn->prepare($countQuery);
    $countStmt->bindParam(':family_id', $family_id, PDO::PARAM_INT);
    $countStmt->execute();
    
    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Family created successfully',
        'family_id' => (int)$family_id
    ]);
    
} catch(Exception $e) {
    error_log("CreateFamily Exception: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>
