<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$user_id  = intval($_GET['user_id']  ?? 0);
$family_id = intval($_GET['family_id'] ?? 0);

if (!$user_id && !$family_id) {
    echo json_encode(['success' => false, 'message' => 'user_id or family_id is required.']);
    exit;
}

try {
    $database = new Database();
    $pdo = $database->connect();
    
    if (!$pdo) {
        echo json_encode(['success' => false, 'message' => 'Database connection failed.']);
        exit;
    }

    // Resolve family_id from user if not given
    if (!$family_id && $user_id) {
        $stmt = $pdo->prepare("SELECT family_id FROM evacuways_users WHERE user_id = ?");
        $stmt->execute([$user_id]);
        $family_id = intval($stmt->fetchColumn());
        if (!$family_id) {
            echo json_encode(['success' => false, 'message' => 'User is not part of any family group.']);
            exit;
        }
    }

    // Family info
    $stmt = $pdo->prepare("SELECT * FROM evacuways_families WHERE family_id = ?");
    $stmt->execute([$family_id]);
    $family = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$family) {
        echo json_encode(['success' => false, 'message' => 'Family group not found.']);
        exit;
    }

    // Members with user details
    $stmt = $pdo->prepare("
        SELECT
            fm.member_id,
            fm.family_id,
            fm.user_id,
            fm.role,
            fm.joined_at,
            u.first_name,
            u.last_name,
            u.contact_number,
            u.gender,
            u.birth_date,
            u.rescue_status,
            u.barangay_code,
            u.latitude,
            u.longitude
        FROM evacuways_family_members fm
        JOIN evacuways_users u ON u.user_id = fm.user_id
        WHERE fm.family_id = ?
        ORDER BY fm.role DESC, fm.joined_at ASC
    ");
    $stmt->execute([$family_id]);
    $members = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Open missing reports
    $stmt = $pdo->prepare("
        SELECT mr.*, CONCAT(u.first_name, ' ', u.last_name) AS reporter_name
        FROM evacuways_missing_reports mr
        JOIN evacuways_users u ON u.user_id = mr.reported_by
        WHERE mr.family_id = ? AND mr.status = 'Open'
        ORDER BY mr.created_at DESC
    ");
    $stmt->execute([$family_id]);
    $missing_reports = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'success'         => true,
        'family'          => $family,
        'members'         => $members,
        'missing_reports' => $missing_reports,
    ]);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>
