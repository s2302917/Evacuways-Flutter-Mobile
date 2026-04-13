<?php
class VehicleModel {
    private $conn;
    private $table = "evacuways_vehicles";

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create($type, $plate, $capacity, $barangay_name, $landmark, $status, $driver_name, $driver_contact) {
        $query = "INSERT INTO " . $this->table . " 
                  (vehicle_type, plate_number, capacity, barangay_name, landmark, status, driver_name, driver_contact) 
                  VALUES (:type, :plate, :capacity, :barangay_name, :landmark, :status, :driver_name, :driver_contact)";
        
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([
            ':type' => $type,
            ':plate' => $plate,
            ':capacity' => $capacity,
            ':barangay_name' => $barangay_name,
            ':landmark' => $landmark,
            ':status' => $status,
            ':driver_name' => $driver_name,
            ':driver_contact' => $driver_contact
        ]);
    }

    public function update($id, $type, $plate, $capacity, $barangay_name, $landmark, $status, $driver_name, $driver_contact) {
        $query = "UPDATE " . $this->table . " 
                  SET vehicle_type = :type, 
                      plate_number = :plate, 
                      capacity = :capacity, 
                      barangay_name = :barangay_name, 
                      landmark = :landmark,
                      status = :status,
                      driver_name = :driver_name,
                      driver_contact = :driver_contact
                  WHERE vehicle_id = :id";
        
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([
            ':id' => $id,
            ':type' => $type,
            ':plate' => $plate,
            ':capacity' => $capacity,
            ':barangay_name' => $barangay_name,
            ':landmark' => $landmark,
            ':status' => $status,
            ':driver_name' => $driver_name,
            ':driver_contact' => $driver_contact
        ]);
    }

    public function getAll() {
        $query = "SELECT * FROM " . $this->table . " ORDER BY created_at DESC, vehicle_id DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getStatusStats() {
        $query = "SELECT status, COUNT(*) as count FROM " . $this->table . " GROUP BY status";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function delete($id) {
        $query = "DELETE FROM " . $this->table . " WHERE vehicle_id = :id";
        $stmt = $this->conn->prepare($query);
        return $stmt->execute([':id' => $id]);
    }
}