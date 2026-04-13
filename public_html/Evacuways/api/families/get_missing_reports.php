<?php
require_once '../config/headers.php';
require_once '../config/database.php';

// Optional filters
$status    = $_GET['status']    ?? 'Open';
$family_id = intval($_GET['family_id'] ?? 0);
$limit     = intval($_GET['limit']     ?? 50);
$offset    = intval($_GET['offset']    ?? 0);

try {
    $database = new Database();
    $pdo = $database->connect();
    
    if (!$pdo) {
        echo json_encode(['success' => false, 'message' => 'Database connection failed.']);
        exit;
    }

    $where   = [];
    $params  = [];

    if ($status !== 'all') {
        $where[]  = 'mr.status = ?';
        $params[] = $status;
    }
    if ($family_id) {
        $where[]  = 'mr.family_id = ?';
        $params[] = $family_id;
    }

    $whereSQL = $where ? ('WHERE ' . implode(' AND ', $where)) : '';

    $stmt = $pdo->prepare("
        SELECT
            mr.*,
            f.family_name,
            f.primary_contact       AS family_contact,
            f.headcount             AS family_headcount,
            CONCAT(u.first_name, ' ', u.last_name) AS reporter_name,
            u.contact_number        AS reporter_contact,
            u.barangay_code         AS reporter_barangay
        FROM evacuways_missing_reports mr
        JOIN evacuways_families f ON f.family_id = mr.family_id
        JOIN evacuways_users    u ON u.user_id    = mr.reported_by
        $whereSQL
        ORDER BY mr.created_at DESC
        LIMIT ? OFFSET ?
    ");
    // PDO::PARAM_INT is better for LIMIT/OFFSET
    $stmt->bindValue(count($params) + 1, $limit, PDO::PARAM_INT);
    $stmt->bindValue(count($params) + 2, $offset, PDO::PARAM_INT);
    
    // Bind the where params
    for ($i = 0; $i < count($params); $i++) {
        $stmt->bindValue($i + 1, $params[$i]);
    }
    
    $stmt->execute();
    $reports = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Total count for pagination
    $countStmt = $pdo->prepare("
        SELECT COUNT(*) FROM evacuways_missing_reports mr $whereSQL
    ");
    for ($i = 0; $i < count($params); $i++) {
        $countStmt->bindValue($i + 1, $params[$i]);
    }
    $countStmt->execute();
    $total = intval($countStmt->fetchColumn());

    echo json_encode([
        'success' => true,
        'total'   => $total,
        'reports' => $reports,
    ]);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>
