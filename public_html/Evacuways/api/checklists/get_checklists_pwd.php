<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_checklists_for_pwd.php - Get checklists for PWD
try {
    $database = new Database();
    $conn = $database->connect();
    
    $query = "SELECT * FROM evacuways_checklists WHERE checklist_type = 'PWD' ORDER BY created_at DESC";
    
    $stmt = $conn->prepare($query);
    $stmt->execute();
    
    $checklists = $stmt->fetchAll(PDO::FETCH_ASSOC);
    http_response_code(200);
    echo json_encode($checklists);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
