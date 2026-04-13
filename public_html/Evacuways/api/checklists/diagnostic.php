<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// DIAGNOSTIC ENDPOINT - Check database status and data
try {
    $database = new Database();
    $conn = $database->connect();
    
    // Get table counts
    $checklistsCount = $conn->query("SELECT COUNT(*) as count FROM evacuways_checklists")->fetch(PDO::FETCH_ASSOC);
    $itemsCount = $conn->query("SELECT COUNT(*) as count FROM evacuways_checklist_items")->fetch(PDO::FETCH_ASSOC);
    
    // Get sample checklists
    $query = "SELECT * FROM evacuways_checklists LIMIT 5";
    $stmt = $conn->prepare($query);
    $stmt->execute();
    $checklists = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get sample items
    $itemQuery = "SELECT * FROM evacuways_checklist_items LIMIT 5";
    $itemStmt = $conn->prepare($itemQuery);
    $itemStmt->execute();
    $items = $itemStmt->fetchAll(PDO::FETCH_ASSOC);
    
    http_response_code(200);
    echo json_encode([
        "database_status" => "connected",
        "checklists_count" => $checklistsCount['count'],
        "items_count" => $itemsCount['count'],
        "sample_checklists" => $checklists,
        "sample_items" => $items,
        "tables_exist" => true
    ]);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode([
        "database_status" => "error",
        "error" => $e->getMessage()
    ]);
}
?>
