<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// DELETE delete_checklist.php - Delete a checklist and its items
try {
    if ($_SERVER['REQUEST_METHOD'] !== 'DELETE') {
        http_response_code(405);
        echo json_encode(["success" => false, "message" => "Method not allowed"]);
        exit;
    }

    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['checklist_id'])) {
        http_response_code(400);
        echo json_encode(["success" => false, "message" => "checklist_id is required"]);
        exit;
    }

    $checklist_id = $input['checklist_id'];

    $database = new Database();
    $conn = $database->connect();

    // Start transaction
    $conn->beginTransaction();

    // Delete checklist items first
    $deleteItemsQuery = "DELETE FROM evacuways_checklist_items WHERE checklist_id = ?";
    $deleteItemsStmt = $conn->prepare($deleteItemsQuery);
    $deleteItemsStmt->execute([$checklist_id]);

    // Delete the checklist
    $deleteChecklistQuery = "DELETE FROM evacuways_checklists WHERE checklist_id = ?";
    $deleteChecklistStmt = $conn->prepare($deleteChecklistQuery);
    $deleteChecklistStmt->execute([$checklist_id]);

    // Commit transaction
    $conn->commit();

    http_response_code(200);
    echo json_encode([
        "success" => true,
        "message" => "Checklist deleted successfully",
        "checklist_id" => $checklist_id
    ]);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
