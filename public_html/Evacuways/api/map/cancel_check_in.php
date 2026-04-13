<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->user_id)) {
    try {
        $database = new Database();
        $db = $database->connect();

        // 1. Find user'sa current presence
        $query = "SELECT resource_type, resource_id, headcount FROM evacuways_user_presences WHERE user_id = :user_id LIMIT 1";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':user_id', $data->user_id);
        $stmt->execute();
        $presence = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($presence) {
            $type = $presence['resource_type'];
            $resource_id = $presence['resource_id'];
            $headcount = $presence['headcount'];

            // 2. Decrement headcount from the resource
            if ($type == 'center') {
                $updateQuery = "UPDATE evacuways_centers SET current_individuals = current_individuals - :headcount WHERE center_id = :resource_id";
            } else {
                $updateQuery = "UPDATE evacuways_vehicles SET current_occupants = current_occupants - :headcount WHERE vehicle_id = :resource_id";
            }
            
            $updateStmt = $db->prepare($updateQuery);
            $updateStmt->bindParam(':headcount', $headcount);
            $updateStmt->bindParam(':resource_id', $resource_id);
            $updateStmt->execute();

            // 3. Remove the presence record
            $deleteQuery = "DELETE FROM evacuways_user_presences WHERE user_id = :user_id";
            $deleteStmt = $db->prepare($deleteQuery);
            $deleteStmt->bindParam(':user_id', $data->user_id);
            $deleteStmt->execute();

            http_response_code(200);
            echo json_encode(["success" => true, "message" => "Check-out successful. Capacity restored."]);
        } else {
            http_response_code(200); 
            echo json_encode(["success" => true, "message" => "No active check-in found."]);
        }

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Incomplete data."]);
}
?>
