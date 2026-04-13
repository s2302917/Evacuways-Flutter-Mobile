<?php
// 1. Point to your database config (Matches Alert and Vehicle models)
require_once __DIR__ . "/../config/database.php"; 

class UserModel {
    private $conn;

    public function __construct() {
        // 2. Initialize the GoDaddy database connection
        $database = new Database();
        $this->conn = $database->connect();
    }

    public function getUsers() {
        try {
            // 3. Query the users table
            $sql = "SELECT * FROM evacuways_users";
            $stmt = $this->conn->prepare($sql);
            $stmt->execute();

            $results = $stmt->fetchAll(PDO::FETCH_ASSOC);

            // 4. Always return an array (even if empty) to prevent dashboard crashes
            return $results ? $results : [];

        } catch (PDOException $e) {
            // If the table doesn't exist yet, return empty so the UI still loads
            return [];
        }
    }

    /**
     * Automatically creates a user account for official personnel.
     * Use when creating Centers, Vehicles/Drivers, or Volunteers.
     */
    public function createAccount($contactNumber, $role, $firstName, $lastName = '') {
        try {
            // 1. Check if user already exists
            $checkSql = "SELECT user_id FROM evacuways_users WHERE contact_number = :contact_number LIMIT 1";
            $checkStmt = $this->conn->prepare($checkSql);
            $checkStmt->execute([':contact_number' => $contactNumber]);
            
            if ($checkStmt->fetch()) {
                // User already has an account, skip creation but return ID if needed
                return true; 
            }

            // 2. Insert new account with default "admin" password
            // Hashing "admin" using BCRYPT
            $passwordHash = password_hash("admin", PASSWORD_BCRYPT);
            
            $insertSql = "INSERT INTO evacuways_users 
                          (contact_number, password_hash, role, first_name, last_name, must_change_password) 
                          VALUES (:contact, :hash, :role, :first, :last, 1)";
            
            $insertStmt = $this->conn->prepare($insertSql);
            return $insertStmt->execute([
                ':contact' => $contactNumber,
                ':hash' => $passwordHash,
                ':role' => $role,
                ':first' => $firstName,
                ':last' => $lastName
            ]);

        } catch (PDOException $e) {
            error_log("Account Creation Error: " . $e->getMessage());
            return false;
        }
    }
}
?>