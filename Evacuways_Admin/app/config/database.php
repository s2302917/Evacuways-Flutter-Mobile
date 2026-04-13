<?php

class Database {

    private $host = "localhost";
    private $db = "GoDaddy_3C";
    private $user = "cd4ddgymub7j";
    private $pass = "Godaddy@3c";


    public function connect(){

        try{

            $pdo = new PDO(
                "mysql:host=".$this->host.";dbname=".$this->db,
                $this->user,
                $this->pass
            );

            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

            return $pdo;

        } catch(PDOException $e){
            echo $e->getMessage();
        }
    }
}