<?php
header('Content-Type: application/json');
require_once '../config/headers.php';
require_once '../config/database.php';

// GET get_checklist.php - Get checklists (all or specific)
// If checklist_id provided: return single checklist
// If no checklist_id: return all checklists with items
$checklist_id = isset($_GET['checklist_id']) ? intval($_GET['checklist_id']) : null;

try {
    $database = new Database();
    $conn = $database->connect();
    
    if (!$conn) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database connection failed"]);
        exit();
    }
    
    // If checklist_id provided, return specific checklist
    if ($checklist_id) {
        $query = "SELECT * FROM evacuways_checklists WHERE checklist_id = :checklist_id";
        $stmt = $conn->prepare($query);
        $stmt->bindParam(':checklist_id', $checklist_id);
        $stmt->execute();
        
        if ($stmt->rowCount() > 0) {
            $checklist = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Get items for this checklist
            $itemQuery = "SELECT * FROM evacuways_checklist_items WHERE checklist_id = ?";
            $itemStmt = $conn->prepare($itemQuery);
            $itemStmt->execute([$checklist_id]);
            $items = $itemStmt->fetchAll(PDO::FETCH_ASSOC);
            $checklist['items'] = $items;
            
            http_response_code(200);
            echo json_encode($checklist);
        } else {
            http_response_code(404);
            echo json_encode(["success" => false, "message" => "Checklist not found"]);
        }
    } else {
        // No ID provided - return ALL checklists with their items
        $query = "SELECT * FROM evacuways_checklists ORDER BY checklist_id DESC";
        $stmt = $conn->prepare($query);
        if (!$stmt) {
            http_response_code(500);
            echo json_encode(["success" => false, "message" => "Query preparation failed"]);
            exit();
        }
        
        $stmt->execute();
        $checklists = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // For each checklist, get its items
        $result = [];
        foreach ($checklists as $checklist) {
            $itemQuery = "SELECT * FROM evacuways_checklist_items WHERE checklist_id = ?";
            $itemStmt = $conn->prepare($itemQuery);
            if ($itemStmt) {
                $itemStmt->execute([$checklist['checklist_id']]);
                $items = $itemStmt->fetchAll(PDO::FETCH_ASSOC);
                $checklist['items'] = $items;
            }
            $result[] = $checklist;
        }
        
        http_response_code(200);
        echo json_encode($result);
    }
    
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "database_error" => $e->getMessage()]);
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
}
?>
