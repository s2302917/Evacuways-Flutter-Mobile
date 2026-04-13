<?php
require_once '../config/headers.php';
require_once '../config/database.php';

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->user_id) && !empty($data->resource_id) && !empty($data->resource_type)) {
    try {
        $database = new Database();
        $db = $database->connect();

        // 0. Auto-create table if not exists (for convenience during development)
        $db->exec("CREATE TABLE IF NOT EXISTS evacuways_user_presences (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            resource_type ENUM('center', 'vehicle') NOT NULL,
            resource_id INT NOT NULL,
            headcount INT DEFAULT 1,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY user_presence (user_id)
        )");

        // 1. Check for existing presence
        $query = "SELECT resource_type, resource_id, headcount FROM evacuways_user_presences WHERE user_id = :user_id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':user_id', $data->user_id);
        $stmt->execute();
        $oldPresence = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($oldPresence) {
            // Decrement old resource
            if ($oldPresence['resource_type'] == 'center') {
                $db->prepare("UPDATE evacuways_centers SET current_individuals = current_individuals - :hc WHERE center_id = :rid")
                   ->execute([':hc' => $oldPresence['headcount'], ':rid' => $oldPresence['resource_id']]);
            } else {
                $db->prepare("UPDATE evacuways_vehicles SET current_occupants = current_occupants - :hc WHERE vehicle_id = :rid")
                   ->execute([':hc' => $oldPresence['headcount'], ':rid' => $oldPresence['resource_id']]);
            }
        }

        // 2. Increment new resource
        if ($data->resource_type == 'center') {
            $db->prepare("UPDATE evacuways_centers SET current_individuals = current_individuals + :hc WHERE center_id = :rid")
               ->execute([':hc' => $data->headcount, ':rid' => $data->resource_id]);
        } else {
            // Ensure vehicle table has current_occupants
            $db->prepare("UPDATE evacuways_vehicles SET current_occupants = current_occupants + :hc WHERE vehicle_id = :rid")
               ->execute([':hc' => $data->headcount, ':rid' => $data->resource_id]);
        }

        // 3. Upsert presence record
        $upsertQuery = "INSERT INTO evacuways_user_presences (user_id, resource_type, resource_id, headcount) 
                        VALUES (:uid, :type, :rid, :hc) 
                        ON DUPLICATE KEY UPDATE resource_type = :type, resource_id = :rid, headcount = :hc";
        $db->prepare($upsertQuery)->execute([
            ':uid' => $data->user_id,
            ':type' => $data->resource_type,
            ':rid' => $data->resource_id,
            ':hc' => $data->headcount
        ]);

        http_response_code(200);
        echo json_encode(["success" => true, "message" => "Check-in recorded. Capacity updated."]);

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Database error: " . $e->getMessage()]);
    }
} else {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Incomplete data."]);
}
?>
