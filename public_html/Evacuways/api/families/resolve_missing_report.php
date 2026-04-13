<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents('php://input'), true);

$report_id   = intval($data['report_id']   ?? 0);
$resolved_by = intval($data['resolved_by'] ?? 0); // admin_id

if (!$report_id || !$resolved_by) {
    echo json_encode(['success' => false, 'message' => 'report_id and resolved_by (admin_id) are required.']);
    exit;
}

try {
    $pdo->beginTransaction();

    $stmt = $pdo->prepare("
        UPDATE evacuways_missing_reports
        SET status = 'Resolved', resolved_by = ?, resolved_at = NOW()
        WHERE report_id = ?
    ");
    $stmt->execute([$resolved_by, $report_id]);

    // Get family_id to reset family missing status if no more open reports
    $stmt = $pdo->prepare("SELECT family_id FROM evacuways_missing_reports WHERE report_id = ?");
    $stmt->execute([$report_id]);
    $family_id = intval($stmt->fetchColumn());

    $stmt = $pdo->prepare("SELECT COUNT(*) FROM evacuways_missing_reports WHERE family_id = ? AND status = 'Open'");
    $stmt->execute([$family_id]);
    $openCount = intval($stmt->fetchColumn());

    if ($openCount === 0) {
        $pdo->prepare("
            UPDATE evacuways_families
            SET missing_count = 0, missing_status = 'Resolved'
            WHERE family_id = ?
        ")->execute([$family_id]);

        $pdo->prepare("
            UPDATE evacuways_users SET missing_count = 0 WHERE family_id = ?
        ")->execute([$family_id]);
    }

    $pdo->commit();
    echo json_encode(['success' => true, 'message' => 'Missing report resolved.']);

} catch (Exception $e) {
    $pdo->rollBack();
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
