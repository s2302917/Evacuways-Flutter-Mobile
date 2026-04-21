<?php
require_once __DIR__ . "/../config/database.php";

class ChecklistModel {
    private $conn;

    public function __construct() {
        $database = new Database();
        $this->conn = $database->connect();
    }

    /**
     * Get all checklist templates (managed by admin)
     */
    public function getTemplates($search = '') {
        try {
            $params = [];
            $whereClause = "";
            
            if (!empty($search)) {
                $whereClause = "WHERE (checklist_name LIKE :search OR description LIKE :search)";
                $params[':search'] = "%$search%";
            }

            $sql = "SELECT c.*, 
                    (SELECT COUNT(*) FROM evacuways_checklist_items WHERE checklist_id = c.checklist_id) as item_count
                    FROM evacuways_checklists c 
                    $whereClause
                    ORDER BY checklist_id DESC";
            $stmt = $this->conn->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error fetching templates: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Get stats on how many users have completed checklists
     */
    public function updateChecklist($id, $name, $desc, $target, $children, $elderly, $pwd) {
        try {
            $sql = "UPDATE evacuways_checklists SET 
                    checklist_name = :name, 
                    description = :desc, 
                    target_role = :target, 
                    for_children = :child, 
                    for_elderly = :elder, 
                    for_pwd = :pwd 
                    WHERE checklist_id = :id";
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute([
                ':id' => $id,
                ':name' => $name,
                ':desc' => $desc,
                ':target' => $target,
                ':child' => $children,
                ':elder' => $elderly,
                ':pwd' => $pwd
            ]);
        } catch (PDOException $e) {
            error_log("Error updating checklist: " . $e->getMessage());
            return false;
        }
    }

    public function updateItem($itemId, $description) {
        try {
            $sql = "UPDATE evacuways_checklist_items SET item_description = :desc WHERE item_id = :id";
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute([
                ':id' => $itemId,
                ':desc' => $description
            ]);
        } catch (PDOException $e) {
            error_log("Error updating item: " . $e->getMessage());
            return false;
        }
    }

    public function getCompletionStats() {
        try {
            $sql = "SELECT 
                        checklist_name, 
                        target_role,
                        COUNT(CASE WHEN is_completed = 1 THEN 1 END) as completed_count,
                        COUNT(user_id) as total_attempts
                    FROM evacuways_checklists 
                    WHERE user_id > 0
                    GROUP BY checklist_name, target_role";
            $stmt = $this->conn->prepare($sql);
            $stmt->execute();
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            return [];
        }
    }

    public function getChecklistItems($checklistId) {
        try {
            $sql = "SELECT * FROM evacuways_checklist_items WHERE checklist_id = :id";
            $stmt = $this->conn->prepare($sql);
            $stmt->execute([':id' => $checklistId]);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            return [];
        }
    }

    public function createChecklist($name, $desc, $target, $children, $elderly, $pwd) {
        try {
            $sql = "INSERT INTO evacuways_checklists 
                    (checklist_name, description, target_role, for_children, for_elderly, for_pwd, user_id) 
                    VALUES (:name, :desc, :target, :children, :elderly, :pwd, 0)";
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute([
                ':name' => $name,
                ':desc' => $desc,
                ':target' => $target,
                ':children' => $children,
                ':elderly' => $elderly,
                ':pwd' => $pwd
            ]);
        } catch (PDOException $e) {
            error_log("Error creating checklist: " . $e->getMessage());
            return false;
        }
    }

    public function addItem($checklistId, $description) {
        try {
            $sql = "INSERT INTO evacuways_checklist_items (checklist_id, item_description) VALUES (?, ?)";
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute([$checklistId, $description]);
        } catch (PDOException $e) {
            return false;
        }
    }

    public function deleteItem($itemId) {
        try {
            $sql = "DELETE FROM evacuways_checklist_items WHERE item_id = ?";
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute([$itemId]);
        } catch (PDOException $e) {
            return false;
        }
    }

    public function deleteChecklist($id) {
        try {
            // First delete items
            $sqlItems = "DELETE FROM evacuways_checklist_items WHERE checklist_id = ?";
            $stmtItems = $this->conn->prepare($sqlItems);
            $stmtItems->execute([$id]);

            // Then delete checklist
            $sql = "DELETE FROM evacuways_checklists WHERE checklist_id = ?";
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute([$id]);
        } catch (PDOException $e) {
            return false;
        }
    }
}
?>
