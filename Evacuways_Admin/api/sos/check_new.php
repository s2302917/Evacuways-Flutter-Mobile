<?php
header('Content-Type: application/json');
require_once __DIR__ . "/../../app/controllers/SOSController.php";

$lastId = $_GET['last_id'] ?? 0;
$controller = new SOSController();

$result = $controller->checkNewSOS($lastId);
echo json_encode($result);
?>
