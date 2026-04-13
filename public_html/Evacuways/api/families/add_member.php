<?php
header('Content-Type: application/json');
require_once '../config/headers.php';
require_once '../config/database.php';

// POST add_member.php - Add user to family group
try {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $family_id = isset($input['family_id']) ? intval($input['family_id']) : null;
    $user_id   = isset($input['user_id']) ? intval($input['user_id']) : null;
    $role      = isset($input['role']) ? trim($input['role']) : 'Member';
    
    if (!$family_id || !$user_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'family_id and user_id are required']);
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

    // 1. Check if user is already in a family
    $stmt = $pdo->prepare("SELECT family_id FROM evacuways_users WHERE user_id = ?");
    $stmt->execute([$user_id]);
    $existing_family_id = $stmt->fetchColumn();

    if ($existing_family_id && $existing_family_id != 0) {
        $pdo->rollBack();
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'User is already a member of another family group']);
        exit();
    }

    // 2. Insert into evacuways_family_members
    $stmt = $pdo->prepare("INSERT INTO evacuways_family_members (family_id, user_id, role, joined_at) VALUES (?, ?, ?, NOW())");
    $stmt->execute([$family_id, $user_id, $role]);

    // 3. Update user's family status
    $stmt = $pdo->prepare("UPDATE evacuways_users SET family_id = ?, is_family = 1 WHERE user_id = ?");
    $stmt->execute([$family_id, $user_id]);

    // 4. Update family headcount
    $stmt = $pdo->prepare("UPDATE evacuways_families SET headcount = headcount + 1 WHERE family_id = ?");
    $stmt->execute([$family_id]);

    $pdo->commit();

    http_response_code(200);
    echo json_encode(['success' => true, 'message' => 'User successfully added to family group']);
    
} catch(Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>
