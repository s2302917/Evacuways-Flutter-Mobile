<?php
header('Content-Type: application/json');
require_once '../config/headers.php';
require_once '../config/database.php';

// GET search_users.php - Search users to add to family
try {
    $query = isset($_GET['query']) ? trim($_GET['query']) : '';
    $family_id = isset($_GET['family_id']) ? intval($_GET['family_id']) : null;
    $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
    $offset = ($page - 1) * $limit;
    
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
    
    // Search users not in this family or without a family
    $searchQuery = "SELECT u.user_id, u.first_name, u.last_name, u.contact_number, 
                           u.rescue_status, u.gender
                    FROM evacuways_users u
                    WHERE (u.family_id IS NULL OR u.family_id != :family_id)
                    AND (CONCAT(u.first_name, ' ', u.last_name) LIKE :search OR u.contact_number LIKE :search)
                    LIMIT :limit OFFSET :offset";
    
    $stmt = $conn->prepare($searchQuery);
    $searchTerm = '%' . $query . '%';
    $stmt->bindParam(':search', $searchTerm);
    $stmt->bindParam(':family_id', $family_id);
    $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindParam(':offset', $offset, PDO::PARAM_INT);
    $stmt->execute();
    
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    http_response_code(200);
    echo json_encode($users);
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
}
?>
