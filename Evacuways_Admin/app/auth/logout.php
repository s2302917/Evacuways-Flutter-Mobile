<?php
/**
 * Logout Controller
 * Path: /app/auth/logout.php
 */
session_start();

// 1. Path Correction: Go up 2 levels to find the config
require_once __DIR__ . "/../../app/config/database.php";

if (isset($_SESSION['admin_id'])) {
    try {
        $database = new Database();
        $db = $database->connect();
        $adminId = $_SESSION['admin_id'];
        $ip = $_SERVER['REMOTE_ADDR'];

        // 2. Insert into the Timeline (Activity Logs)
        // We use the new table we discussed with the admin_id foreign key
        $logSql = "INSERT INTO evacuways_admin_logs (admin_id, action, details, ip_address) 
                   VALUES (?, 'Logout', 'User manually logged out', ?)";
        $stmt = $db->prepare($logSql);
        $stmt->execute([$adminId, $ip]);

        // 3. Update the admin table's last_login/activity if needed
        $updateSql = "UPDATE evacuways_admins SET last_login = NOW() WHERE admin_id = ?";
        $updateStmt = $db->prepare($updateSql);
        $updateStmt->execute([$adminId]);

    } catch (PDOException $e) {
        // Log error silently to stay functional
        error_log("Logout Logging Error: " . $e->getMessage());
    }
}

// 4. Clear and Destroy Session
$_SESSION = array();
session_destroy();

// 5. Redirect to the login page (index.php in the root)
header("Location: ../../index.php");
exit();