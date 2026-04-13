<?php
// api/config/database.php

class Database {
    private $host = "localhost";
    private $db   = "GoDaddy_3C";
    private $user = "cd4ddgymub7j";
    private $pass = "Godaddy@3c";

    public function connect() {
        try {
            $pdo = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db . ";charset=utf8mb4",
                $this->user,
                $this->pass
            );
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
            return $pdo;
        } catch (PDOException $e) {
            // Log error silently, don't echo (echo breaks JSON responses)
            error_log("Database Connection Error: " . $e->getMessage());
            return null;
        }
    }
}
?>
