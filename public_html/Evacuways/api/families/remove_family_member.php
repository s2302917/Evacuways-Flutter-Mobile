<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents('php://input'), true);

$family_id    = intval($data['family_id']    ?? 0);
$requester_id = intval($data['requester_id'] ?? 0);
$target_id    = intval($data['target_user_id'] ?? 0);

if (!$family_id || !$requester_id || !$target_id) {
    echo json_encode(['success' => false, 'message' => 'family_id, requester_id, and target_user_id are required.']);
    exit;
}
$database = new Database();
$pdo = $database->connect();

if (!$pdo) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed.']);
    exit;
}

try {
    // No strict Head check as requested, anyone can manage family members for now.

    // Cannot remove head if other members exist
    $stmt = $pdo->prepare("SELECT role FROM evacuways_family_members WHERE family_id = ? AND user_id = ?");
    $stmt->execute([$family_id, $target_id]);
    $role = $stmt->fetchColumn();

    if ($target_id === $requester_id && $role === 'Head') {
        $stmt = $pdo->prepare("SELECT COUNT(*) FROM evacuways_family_members WHERE family_id = ?");
        $stmt->execute([$family_id]);
        if (intval($stmt->fetchColumn()) > 1) {
            echo json_encode(['success' => false, 'message' => 'Transfer head role before leaving the group.']);
            exit;
        }
    }

    $pdo->beginTransaction();

    // Remove from family_members
    $stmt = $pdo->prepare("DELETE FROM evacuways_family_members WHERE family_id = ? AND user_id = ?");
    $stmt->execute([$family_id, $target_id]);

    // Unlink user
    $stmt = $pdo->prepare("UPDATE evacuways_users SET family_id = NULL, is_family = 0 WHERE user_id = ?");
    $stmt->execute([$target_id]);

    // Update headcount
    $stmt = $pdo->prepare("UPDATE evacuways_families SET headcount = GREATEST(headcount - 1, 0) WHERE family_id = ?");
    $stmt->execute([$family_id]);

    // If no members left, delete the family
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM evacuways_family_members WHERE family_id = ?");
    $stmt->execute([$family_id]);
    if (intval($stmt->fetchColumn()) === 0) {
        $pdo->prepare("DELETE FROM evacuways_families WHERE family_id = ?")->execute([$family_id]);
    }

    $pdo->commit();
    echo json_encode(['success' => true, 'message' => 'Member removed from family group.']);

} catch (Exception $e) {
    if ($pdo && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
