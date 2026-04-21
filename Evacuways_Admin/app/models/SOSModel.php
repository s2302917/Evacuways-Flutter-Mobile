<?php
require_once __DIR__ . "/../config/database.php";

class SOSModel {
    private $conn;

    public function __construct() {
        $database = new Database();
        $this->conn = $database->connect();
    }

    /**
     * Get all SOS and Emergency requests with user details
     */
    public function getSOSRequests($status = null) {
        try {
            $params = [];
            $whereReq = "1=1";
            $whereRep = "1=1";
            $whereMiss = "1=1";
            
            if ($status) {
                $whereReq = "r.status = :status";
                $whereRep = "rep.status = :status";
                $whereMiss = "mr.status = :status_miss";
                $params[':status'] = $status;
                // Normalize status for missing reports if needed (mapping 'Pending' to 'Open')
                $params[':status_miss'] = ($status === 'Pending') ? 'Open' : $status;
            }

            $sql = "
                SELECT 
                    'support' as source, r.request_id, r.user_id, r.city_id, r.barangay_id, 
                    r.subject, r.message, r.request_type, r.status, 
                    COALESCE(NULLIF(r.latitude, 0), NULLIF(u.latitude, 0)) as latitude, 
                    COALESCE(NULLIF(r.longitude, 0), NULLIF(u.longitude, 0)) as longitude, 
                    r.created_at,
                    u.first_name, u.last_name, u.contact_number
                FROM evacuways_support_requests r
                LEFT JOIN evacuways_users u ON r.user_id = u.user_id
                WHERE $whereReq

                UNION ALL

                SELECT 
                    'report' as source, rep.report_id as request_id, rep.generated_by as user_id, 
                    rep.city_id, rep.barangay_id, rep.subject, rep.message, rep.report_type as request_type, 
                    rep.status, 
                    COALESCE(NULLIF(rep.latitude, 0), NULLIF(u.latitude, 0)) as latitude, 
                    COALESCE(NULLIF(rep.longitude, 0), NULLIF(u.longitude, 0)) as longitude, 
                    rep.generated_at as created_at,
                    u.first_name, u.last_name, u.contact_number
                FROM evacuways_reports rep
                LEFT JOIN evacuways_users u ON rep.generated_by = u.user_id
                WHERE $whereRep

                UNION ALL

                SELECT 
                    'missing' as source, mr.report_id as request_id, mr.reported_by as user_id,
                    NULL as city_id, NULL as barangay_id, 
                    CONCAT('Missing: ', mr.missing_count, ' Persons') as subject,
                    mr.notes as message, 'Missing Person' as request_type, 
                    mr.status, 
                    NULLIF(u.latitude, 0) as latitude, 
                    NULLIF(u.longitude, 0) as longitude, 
                    mr.created_at,
                    u.first_name, u.last_name, u.contact_number
                FROM evacuways_missing_reports mr
                LEFT JOIN evacuways_users u ON mr.reported_by = u.user_id
                WHERE $whereMiss

                ORDER BY 
                    CASE WHEN status IN ('Pending', 'Open', 'Reported') THEN 1 ELSE 2 END,
                    created_at DESC
            ";
            
            $stmt = $this->conn->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            error_log("Error fetching SOS: " . $e->getMessage());
            return [];
        }
    }

    /**
     * Fallback method to get only support requests if the combined query fails
     */
    private function getSupportRequestsOnly($status = null) {
        try {
            $params = [];
            $whereClause = "WHERE 1=1";
            if ($status) {
                $whereClause .= " AND r.status = :status";
                $params[':status'] = $status;
            }
            $sql = "SELECT 'support' as source, r.*, u.first_name, u.last_name, u.contact_number
                    FROM evacuways_support_requests r
                    LEFT JOIN evacuways_users u ON r.user_id = u.user_id
                    $whereClause
                    ORDER BY created_at DESC";
            $stmt = $this->conn->prepare($sql);
            $stmt->execute($params);
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            return [];
        }
    }

    /**
     * Update the status of an SOS request or Report
     */
    public function updateStatus($id, $status, $source = 'support') {
        try {
            $table = 'evacuways_support_requests';
            $idCol = 'request_id';
            
            if ($source === 'report') {
                $table = 'evacuways_reports';
                $idCol = 'report_id';
            } else if ($source === 'missing') {
                $table = 'evacuways_missing_reports';
                $idCol = 'report_id';
                $status = ($status === 'Resolved') ? 'Resolved' : 'Open'; // Normalize for missing reports
            }
            
            $sql = "UPDATE $table SET status = :status WHERE $idCol = :id";
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute([
                ':id' => $id,
                ':status' => $status
            ]);
        } catch (PDOException $e) {
            error_log("Error updating status: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Get counts for dashboard/stats
     */
    public function getCounts() {
        try {
            // We use a safe subquery for reports that doesn't depend on 'status' if it might be missing
            // However, after the user runs the SQL, 'status' will exist. 
            // To be safe before that, we'll try-catch or use conditional logic.
            // For now, we'll assume they might not have run it yet and use a more basic union.
            $sql = "SELECT 
                        SUM(total) as total,
                        SUM(pending) as pending,
                        SUM(resolved) as resolved
                    FROM (
                        SELECT 
                            COUNT(*) as total,
                            SUM(CASE WHEN status = 'Pending' OR status = 'Open' THEN 1 ELSE 0 END) as pending,
                            SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) as resolved
                        FROM evacuways_support_requests
                        
                        UNION ALL
                        
                        SELECT 
                            COUNT(*) as total,
                            SUM(CASE WHEN status = 'Reported' OR status = 'Pending' THEN 1 ELSE 0 END) as pending, 
                            SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) as resolved
                        FROM evacuways_reports

                        UNION ALL

                        SELECT 
                            COUNT(*) as total,
                            SUM(CASE WHEN status = 'Open' OR status = 'Pending' THEN 1 ELSE 0 END) as pending,
                            SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) as resolved
                        FROM evacuways_missing_reports
                    ) as combined";
            $stmt = $this->conn->prepare($sql);
            $stmt->execute();
            return $stmt->fetch(PDO::FETCH_ASSOC);
        } catch (PDOException $e) {
            // Fallback for just support requests
            try {
                $sql = "SELECT COUNT(*) as total, SUM(CASE WHEN status = 'Pending' THEN 1 ELSE 0 END) as pending, SUM(CASE WHEN status = 'Resolved' THEN 1 ELSE 0 END) as resolved FROM evacuways_support_requests";
                $stmt = $this->conn->prepare($sql);
                $stmt->execute();
                return $stmt->fetch(PDO::FETCH_ASSOC);
            } catch (PDOException $e2) {
                return ['total' => 0, 'pending' => 0, 'resolved' => 0];
            }
        }
    }

    /**
     * Check for the newest pending SOS ID
     */
    public function getLatestPendingId() {
        try {
            // Only checking support requests for now as they are the primary real-time source
            $sql = "SELECT MAX(request_id) as last_id 
                    FROM evacuways_support_requests 
                    WHERE status = 'Pending'";
            $stmt = $this->conn->prepare($sql);
            $stmt->execute();
            $result = $stmt->fetch(PDO::FETCH_ASSOC);
            return $result['last_id'] ?? 0;
        } catch (PDOException $e) {
            return 0;
        }
    }
    /**
     * Delete an SOS request or Report
     */
    public function deleteSOS($id, $source = 'support') {
        try {
            $table = 'evacuways_support_requests';
            $idCol = 'request_id';
            
            if ($source === 'report') {
                $table = 'evacuways_reports';
                $idCol = 'report_id';
            } else if ($source === 'missing') {
                $table = 'evacuways_missing_reports';
                $idCol = 'report_id';
            }
            
            $sql = "DELETE FROM $table WHERE $idCol = :id";
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute([':id' => $id]);
        } catch (PDOException $e) {
            error_log("Error deleting SOS: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Edit an SOS request or Report (Update message/type/subject)
     */
    public function editSOS($id, $data, $source = 'support') {
        try {
            $table = 'evacuways_support_requests';
            $idCol = 'request_id';
            
            if ($source === 'report') {
                $table = 'evacuways_reports';
                $idCol = 'report_id';
            } else if ($source === 'missing') {
                $table = 'evacuways_missing_reports';
                $idCol = 'report_id';
            }
            
            // Basic fields allowed for editing
            $fields = [];
            $params = [':id' => $id];
            
            if (isset($data['message'])) {
                $fields[] = ($source === 'missing') ? "notes = :message" : "message = :message";
                $params[':message'] = $data['message'];
            }
            if (isset($data['request_type'])) {
                if ($source === 'report') $fields[] = "report_type = :type";
                else if ($source === 'support') $fields[] = "request_type = :type";
                // Missing reports don't have a specific type column (it's always Missing Person)
                if (isset($fields[count($fields)-1])) $params[':type'] = $data['request_type'];
            }
            if (isset($data['subject'])) {
                $fields[] = "subject = :subject";
                $params[':subject'] = $data['subject'];
            }

            if (empty($fields)) return false;

            $sql = "UPDATE $table SET " . implode(", ", $fields) . " WHERE $idCol = :id";
            $stmt = $this->conn->prepare($sql);
            return $stmt->execute($params);
        } catch (PDOException $e) {
            error_log("Error editing SOS: " . $e->getMessage());
            return false;
        }
    }
}
?>
