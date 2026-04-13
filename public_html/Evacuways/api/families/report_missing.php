<?php
header('Content-Type: application/json');
require_once '../config/headers.php';
require_once '../config/database.php';

// POST report_missing.php - Report family member(s) as missing
try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $family_id     = isset($input['family_id']) ? intval($input['family_id']) : null;
    $reported_by   = isset($input['reported_by']) ? intval($input['reported_by']) : null;
    $missing_count = isset($input['missing_count']) ? intval($input['missing_count']) : 0;
    $notes         = isset($input['notes']) ? trim($input['notes']) : '';
    
    if (!$family_id || !$reported_by) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'family_id and reported_by are required']);
        exit();
    }

    if ($missing_count <= 0) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Missing count must be greater than zero']);
        exit();
    }
    
    $database = new Database();
    $pdo = $database->connect();
    
    if (!$pdo) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Database connection failed']);
        exit();
    }

    $pdo->beginTransaction();

    // 1. Mark existing open reports for this family as 'Replaced' (optional, but keeps things clean)
    $stmt = $pdo->prepare("UPDATE evacuways_missing_reports SET status = 'Resolved' WHERE family_id = ? AND status = 'Open'");
    $stmt->execute([$family_id]);
    
    // 2. Create a new missing report record
    $query = "INSERT INTO evacuways_missing_reports 
              (family_id, reported_by, missing_count, notes, status, created_at) 
              VALUES (:family_id, :reported_by, :missing_count, :notes, 'Open', NOW())";
    $stmt = $pdo->prepare($query);
    
    $stmt->bindParam(':family_id', $family_id);
    $stmt->bindParam(':reported_by', $reported_by);
    $stmt->bindParam(':missing_count', $missing_count);
    $stmt->bindParam(':notes', $notes);
    $stmt->execute();
    
    $report_id = $pdo->lastInsertId();
    
    // 3. Update family summary status
    $updateFamily = "UPDATE evacuways_families SET 
                     missing_count = :missing_count,
                     missing_reported_by = :reported_by,
                     missing_report_at = NOW(),
                     missing_notes = :notes,
                     missing_status = 'Missing'
                     WHERE family_id = :family_id";
    $stmt = $pdo->prepare($updateFamily);
    $stmt->bindParam(':missing_count', $missing_count);
    $stmt->bindParam(':reported_by', $reported_by);
    $stmt->bindParam(':notes', $notes);
    $stmt->bindParam(':family_id', $family_id);
    $stmt->execute();

    // 4. Create a support request for visibility in the admin panel if needed
    $supportQuery = "INSERT INTO evacuways_support_requests 
                    (user_id, subject, message, request_type, status, created_at) 
                    VALUES (:user_id, :subject, :message, 'Missing Person', 'Pending', NOW())";
    $stmt = $pdo->prepare($supportQuery);
    
    $subject = "URGENT: $missing_count family member(s) reported missing";
    $message = "Family ID: $family_id\nNotes: $notes";
    
    $stmt->bindParam(':user_id', $reported_by);
    $stmt->bindParam(':subject', $subject);
    $stmt->bindParam(':message', $message);
    $stmt->execute();
    
    $pdo->commit();

    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'Missing report submitted successfully', 'report_id' => $report_id]);
    
} catch(Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>
