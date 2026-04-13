<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents('php://input'), true);

$family_id      = intval($data['family_id']      ?? 0);
$requester_id   = intval($data['requester_id']   ?? 0);  // must be Head
$contact_number = trim($data['contact_number']   ?? '');

if (!$family_id || !$requester_id || !$contact_number) {
    echo json_encode(['success' => false, 'message' => 'family_id, requester_id, and contact_number are required.']);
    exit;
}

try {
    $database = new Database();
    $pdo = $database->connect();
    
    if (!$pdo) {
        echo json_encode(['success' => false, 'message' => 'Database connection failed.']);
        exit;
    }

    // Anyone currently in the system can add members, no strict Head check as requested.
    // However, we should still have a requester_id for logging or future use.

    // Find user by contact number
    $stmt = $pdo->prepare("SELECT user_id, first_name, last_name, family_id FROM evacuways_users WHERE contact_number = ? LIMIT 1");
    $stmt->execute([$contact_number]);
    $target = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$target) {
        echo json_encode(['success' => false, 'message' => 'No user found with that contact number.']);
        exit;
    }

    if ($target['family_id']) {
        echo json_encode(['success' => false, 'message' => 'That user is already in a family group.']);
        exit;
    }

    $target_user_id = intval($target['user_id']);

    $pdo->beginTransaction();

    // Add to family_members
    $stmt = $pdo->prepare("INSERT INTO evacuways_family_members (family_id, user_id, role) VALUES (?, ?, 'Member')");
    $stmt->execute([$family_id, $target_user_id]);

    // Update user record
    $stmt = $pdo->prepare("UPDATE evacuways_users SET family_id = ?, is_family = 1 WHERE user_id = ?");
    $stmt->execute([$family_id, $target_user_id]);

    // Update family headcount
    $stmt = $pdo->prepare("UPDATE evacuways_families SET headcount = headcount + 1 WHERE family_id = ?");
    $stmt->execute([$family_id]);

    $pdo->commit();

    echo json_encode([
        'success' => true,
        'message' => $target['first_name'] . ' ' . $target['last_name'] . ' added to family.',
        'added_user' => [
            'user_id'    => $target_user_id,
            'first_name' => $target['first_name'],
            'last_name'  => $target['last_name'],
            'role'       => 'Member',
        ],
    ]);

} catch (Exception $e) {
    if (isset($pdo) && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>
