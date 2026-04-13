<?php
session_start();
require_once dirname(__DIR__) . '/config/database.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $database = new Database();
    $pdo = $database->connect();

    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    try {
        /**
         * UPDATED JOIN:
         * We now link evacuways_admins.city_code to evacuways_cities.city_code.
         * This translates your PSGC code (e.g., 064501000) into the 
         * integer ID (e.g., 1) required for database integrity.
         */
        $query = "
            SELECT a.*, c.city_id AS resolved_city_id 
            FROM evacuways_admins a
            LEFT JOIN evacuways_cities c ON a.city_code = c.city_code 
            WHERE a.email = :email 
            LIMIT 1";
            
        $stmt = $pdo->prepare($query);
        $stmt->execute(['email' => $email]);
        $admin = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($admin) {
            // Check 1: Secure Hash | Check 2: Plain Text (Migration backup)
            $hashCheck = password_verify($password, $admin['password_hash']);
            $plainCheck = ($password === $admin['password_hash']);

            if ($hashCheck || $plainCheck) {
                session_regenerate_id(true);
                
                // --- SESSION STORAGE ---
                $_SESSION['admin_id'] = $admin['admin_id'];
                $_SESSION['full_name'] = $admin['full_name'];
                
                // We store the resolved integer ID. If the join fails, 
                // we fall back to the admin table's own city_id column.
                $_SESSION['city_id']   = $admin['resolved_city_id'] ?? $admin['city_id'];
                $_SESSION['city_code'] = $admin['city_code']; 

                // Update last login timestamp
                $updateStmt = $pdo->prepare("UPDATE evacuways_admins SET last_login = NOW() WHERE admin_id = ?");
                $updateStmt->execute([$admin['admin_id']]);

                header("Location: ../views/dashboard/dashboard.php");
                exit();
            }
        }
        
        // Invalid credentials
        header("Location: ../../index.php?error=1");
        exit();

    } catch (PDOException $e) {
        error_log("Login Error: " . $e->getMessage());
        die("A database error occurred. Please try again later.");
    }
}