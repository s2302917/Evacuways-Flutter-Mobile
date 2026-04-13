<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . "/../../../app/controllers/VehicleController.php";
$vehicleController = new VehicleController();

$vehicleController->handleRequest();
$vehicles = $vehicleController->index();
$statusData = $vehicleController->getStatusStats();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Evacuation Vehicles | Evacuways Admin</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Sharp" />
    <link rel="stylesheet" href="../../../public/css/style.css?v=<?php echo time(); ?>">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>

<div class="container">
    <aside>
        <div class="top">
            <div class="logo">
                <img src="../../../public/images/logo.png" alt="Evacuways Logo" class="logo-img">
                <h2>Evacuways Admin</h2>
            </div>
            <div class="close" id="close_btn">
                <span class="material-symbols-sharp">close</span>
            </div>
        </div>

        <div class="sidebar">
            <a href="../../views/dashboard/dashboard.php"><span class="material-symbols-sharp">grid_view</span><h3>Dashboard</h3></a>
            <a href="../alerts/alerts.php"><span class="material-symbols-sharp">warning</span><h3>Emergency Alerts</h3></a>
            <a href="vehicles.php" class="active"><span class="material-symbols-sharp">airport_shuttle</span><h3>Evacuation Vehicles</h3></a>
            <a href="../centers/centers.php"><span class="material-symbols-sharp">location_city</span><h3>Evacuation Centers</h3></a>
            <a href="../families/families.php"><span class="material-symbols-sharp">groups</span><h3>Registered Families</h3></a>
            <a href="../messages/messages.php"><span class="material-symbols-sharp">mail</span><h3>Messages</h3></a>
            <a href="../settings/settings.php"><span class="material-symbols-sharp">settings</span><h3>Settings</h3></a>
            <a href="../../auth/logout.php"><span class="material-symbols-sharp">logout</span><h3>Logout</h3></a>
        </div>
    </aside>

    <main>
        <h1>Evacuation Vehicles</h1>
        
        <div class="form-container">
            <h3>Register New Vehicle</h3>
            <form action="vehicles.php" method="POST" class="form-group-wrapper">
                
                <div class="grid-3-col">
                    <div class="input-box">
                        <p>Vehicle Type</p>
                        <select name="vehicle_type" required>
                            <option value="Ambulance">Ambulance</option>
                            <option value="Rescue Truck">Rescue Truck</option>
                            <option value="Bus">Bus</option>
                            <option value="Patrol Car">Patrol Car</option>
                            <option value="Boat">Boat</option>
                        </select>
                    </div>
                    <div class="input-box">
                        <p>Plate Number / Unit ID</p>
                        <input type="text" name="plate_number" placeholder="e.g. ABC-1234" required>
                    </div>
                    <div class="input-box">
                        <p>Capacity (Persons)</p>
                        <input type="number" name="capacity" placeholder="e.g. 20" required>
                    </div>
                </div>

                <div class="grid-3-col">
                    <div class="input-box">
                        <p>Driver Name</p>
                        <input type="text" name="driver_name" placeholder="Enter driver name" required>
                    </div>
                    <div class="input-box">
                        <p>Driver Contact</p>
                        <input type="text" name="driver_contact" placeholder="e.g. 09123456789" required>
                    </div>
                    <div class="input-box">
                        <p>Status</p>
                        <select name="status" required>
                            <option value="Standby">Standby</option>
                            <option value="Deployed">Deployed</option>
                            <option value="Maintenance">Maintenance</option>
                        </select>
                    </div>
                </div>

                <div class="grid-2-col">
                    <div class="input-box">
                        <p>Assigned Barangay</p>
                        <select name="barangay_name" id="barangay_dropdown" required>
                            <option value="" disabled selected>Loading Barangays...</option>
                        </select>
                    </div>
                    <div class="input-box">
                        <p>Meeting Landmark</p>
                        <input type="text" name="landmark" placeholder="e.g. Brgy. Plaza, Covered Court" required>
                    </div>
                </div>

                <button type="submit" name="create_vehicle" class="btn-submit">Add Vehicle</button>
            </form>
        </div>

        <div class="recent_alerts">
            <h2>Vehicle Fleet List</h2>
            <table>
                <thead>
                    <tr>
                        <th>Vehicle Details</th>
                        <th>Driver Info</th>
                        <th>Location Assignment</th>
                        <th>Status</th>
                        <th class="text-center">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (!empty($vehicles)): ?>
                        <?php foreach($vehicles as $vehicle): 
                            $status = htmlspecialchars($vehicle['status'] ?? '');
                            $statusColor = match($status) {
                                'Deployed' => 'warning',
                                'Standby' => 'success',
                                'Maintenance' => 'danger',
                                default => 'text-light'
                            };
                        ?>
                        <tr>
                            <td>
                                <b><?= htmlspecialchars($vehicle['plate_number']) ?></b><br>
                                <small class="text-muted"><?= htmlspecialchars($vehicle['vehicle_type']) ?> (<?= htmlspecialchars($vehicle['capacity']) ?> pax)</small>
                            </td>
                            <td>
                                <b><?= htmlspecialchars($vehicle['driver_name'] ?? 'N/A') ?></b><br>
                                <small class="text-muted"><?= htmlspecialchars($vehicle['driver_contact'] ?? 'N/A') ?></small>
                            </td>
                            <td>
                                <b><?= htmlspecialchars($vehicle['barangay_name'] ?? 'Unknown Brgy') ?></b><br>
                                <small class="text-muted"><span class="material-symbols-sharp icon-sm">location_on</span> <?= htmlspecialchars($vehicle['landmark'] ?? 'No landmark set') ?></small>
                            </td>
                            <td class="<?= $statusColor ?>"><b><?= $status ?></b></td>
                            <td class="table-actions">
                                
                                <button type="button" class="btn-icon edit" onclick="openEditModal(
                                    '<?= $vehicle['vehicle_id'] ?>', 
                                    '<?= htmlspecialchars(addslashes($vehicle['vehicle_type'])) ?>', 
                                    '<?= htmlspecialchars(addslashes($vehicle['plate_number'])) ?>', 
                                    '<?= $vehicle['capacity'] ?>', 
                                    '<?= htmlspecialchars(addslashes($vehicle['barangay_name'])) ?>', 
                                    '<?= htmlspecialchars(addslashes($vehicle['landmark'] ?? '')) ?>', 
                                    '<?= $vehicle['status'] ?>',
                                    '<?= htmlspecialchars(addslashes($vehicle['driver_name'] ?? '')) ?>',
                                    '<?= htmlspecialchars(addslashes($vehicle['driver_contact'] ?? '')) ?>'
                                )">
                                    <span class="material-symbols-sharp">edit</span>
                                </button>

                                <a href="vehicles.php?delete=<?= $vehicle['vehicle_id'] ?>" class="btn-icon delete" onclick="return confirm('Are you sure you want to remove this vehicle?')">
                                    <span class="material-symbols-sharp">delete</span>
                                </a>

                            </td>
                        </tr>
                        <?php endforeach; ?>
                    <?php else: ?>
                        <tr>
                            <td colspan="5" class="empty-table">No vehicles registered yet.</td>
                        </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </main>

    <div class="right">
        <div class="top">
            <button id="menu_bar"><span class="material-symbols-sharp">menu</span></button>
            <div class="theme-toggler">
                <span class="material-symbols-sharp active">light_mode</span>
                <span class="material-symbols-sharp">dark_mode</span>
            </div>
        </div>
        
        <div class="statistics">
            <h2>Fleet Summary</h2>
            <div class="stat">
                <span class="material-symbols-sharp">airport_shuttle</span>
                <div>
                    <h3>Total Vehicles</h3>
                    <p><b><?= count($vehicles) ?></b></p>
                </div>
            </div>
            
            <div class="chart-container custom-chart-box">
                <h3 class="mb-1">Vehicle Status Overview</h3>
                <canvas id="vehicleStatusChart"></canvas>
            </div>
        </div>
    </div>
</div>

<div class="modal-overlay" id="updateModal" style="display: none;">
    <div class="modal-content">
        <h3 class="mb-1">Update Vehicle Info</h3>
        <form action="vehicles.php" method="POST" class="form-group-wrapper text-left">
            <input type="hidden" name="vehicle_id" id="update_vehicle_id">
            
            <div class="grid-2-col">
                <div class="input-box">
                    <p>Vehicle Type</p>
                    <select name="vehicle_type" id="update_type" required>
                        <option value="Ambulance">Ambulance</option>
                        <option value="Rescue Truck">Rescue Truck</option>
                        <option value="Bus">Bus</option>
                        <option value="Patrol Car">Patrol Car</option>
                        <option value="Boat">Boat</option>
                    </select>
                </div>
                <div class="input-box">
                    <p>Plate Number</p>
                    <input type="text" name="plate_number" id="update_plate" required>
                </div>
            </div>
            
            <div class="grid-2-col">
                <div class="input-box">
                    <p>Capacity</p>
                    <input type="number" name="capacity" id="update_capacity" required>
                </div>
                <div class="input-box">
                    <p>Status</p>
                    <select name="status" id="update_status" required>
                        <option value="Standby">Standby</option>
                        <option value="Deployed">Deployed</option>
                        <option value="Maintenance">Maintenance</option>
                    </select>
                </div>
            </div>

            <div class="grid-2-col">
                <div class="input-box">
                    <p>Driver Name</p>
                    <input type="text" name="driver_name" id="update_driver_name" required>
                </div>
                <div class="input-box">
                    <p>Driver Contact</p>
                    <input type="text" name="driver_contact" id="update_driver_contact" required>
                </div>
            </div>
            
            <div class="grid-2-col">
                <div class="input-box">
                    <p>Assigned Barangay</p>
                    <select name="barangay_name" id="update_barangay" required>
                        <option value="" disabled selected>Loading Barangays...</option>
                    </select>
                </div>
                <div class="input-box">
                    <p>Meeting Landmark</p>
                    <input type="text" name="landmark" id="update_landmark" required>
                </div>
            </div>
            
            <button type="submit" name="update_vehicle" class="btn-submit">Save Changes</button>
            <button type="button" class="btn-submit btn-cancel" onclick="closeEditModal()">Cancel</button>
        </form>
    </div>
</div>

<script src="../../../public/js/script.js"></script>

<script>
    // JS LOCATION HANDLER
    document.addEventListener("DOMContentLoaded", function() {
        // PSGC API Code for Bacolod City
        const cityCode = '064501000'; 
        const apiUrl = `https://psgc.gitlab.io/api/cities-municipalities/${cityCode}/barangays/`;

        const barangayDropdowns = [
            document.getElementById('barangay_dropdown'), 
            document.getElementById('update_barangay')
        ];

        fetch(apiUrl)
            .then(response => response.json())
            .then(data => {
                data.sort((a, b) => a.name.localeCompare(b.name));

                barangayDropdowns.forEach(dropdown => {
                    if (!dropdown) return; 
                    dropdown.innerHTML = '<option value="" disabled selected>Select Barangay</option>';
                    
                    data.forEach(barangay => {
                        const option = document.createElement('option');
                        option.value = barangay.name; 
                        option.textContent = barangay.name;
                        dropdown.appendChild(option);
                    });
                });
            })
            .catch(error => {
                console.error("Error fetching barangays:", error);
                barangayDropdowns.forEach(dropdown => {
                    if(dropdown) dropdown.innerHTML = '<option value="">Error loading barangays</option>';
                });
            });
    });

    // Edit Modal Logic updated to include landmark
    function openEditModal(id, type, plate, capacity, barangayName, landmark, status, driverName, driverContact) {
        document.getElementById('update_vehicle_id').value = id;
        document.getElementById('update_type').value = type;
        document.getElementById('update_plate').value = plate;
        document.getElementById('update_capacity').value = capacity;
        document.getElementById('update_landmark').value = landmark;
        document.getElementById('update_status').value = status;
        document.getElementById('update_driver_name').value = driverName;
        document.getElementById('update_driver_contact').value = driverContact;
        
        // Timeout ensures the JS API fetch has time to load options before setting the value
        setTimeout(() => {
            document.getElementById('update_barangay').value = barangayName;
        }, 500);
        
        document.getElementById('updateModal').style.display = 'flex';
    }

    function closeEditModal() {
        document.getElementById('updateModal').style.display = 'none';
    }

    // Chart.js Configuration
    document.addEventListener('DOMContentLoaded', function() {
        const statusCtx = document.getElementById('vehicleStatusChart').getContext('2d');
        
        const statusLabels = <?= json_encode($statusData['labels'] ?? []) ?>;
        const statusValues = <?= json_encode($statusData['values'] ?? []) ?>;

        const getBgColor = (label) => {
            if(label === 'Standby') return '#41f1b6'; 
            if(label === 'Deployed') return '#ffbb55'; 
            if(label === 'Maintenance') return '#ff7782'; 
            return '#7380ec';
        };

        const bgColors = statusLabels.map(getBgColor);

        new Chart(statusCtx, {
            type: 'doughnut',
            data: {
                labels: statusLabels,
                datasets: [{
                    data: statusValues,
                    backgroundColor: bgColors,
                    borderWidth: 0 
                }]
            },
            options: {
                responsive: true,
                cutout: '70%',
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            padding: 20,
                            usePointStyle: true 
                        }
                    }
                }
            }
        });
    });
</script>
</body>
</html>