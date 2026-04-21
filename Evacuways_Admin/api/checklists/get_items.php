<?php
header('Content-Type: application/json');
require_once __DIR__ . "/../../app/models/ChecklistModel.php";

$id = $_GET['id'] ?? 0;

if (!$id) {
    echo json_encode(['error' => 'Invalid ID']);
    exit;
}

$model = new ChecklistModel();
$items = $model->getChecklistItems($id);

echo json_encode($items);
?>
