<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . "/../../../app/controllers/CenterController.php";
$centerController = new CenterController();

$centerController->handleRequest();
$centers = $centerController->index();
$statusData = $centerController->getStatusStats();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Evacuation Centers | Evacuways Admin</title>
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
            <a href="../vechicles/vehicles.php"><span class="material-symbols-sharp">airport_shuttle</span><h3>Evacuation Vehicles</h3></a>
            <a href="centers.php" class="active"><span class="material-symbols-sharp">location_city</span><h3>Evacuation Centers</h3></a>
            <a href="../families/families.php"><span class="material-symbols-sharp">groups</span><h3>Registered Families</h3></a>
            <a href="../volunteers/volunteers.php"><span class="material-symbols-sharp">volunteer_activism</span><h3>Volunteers</h3></a>
            <a href="../messages/messages.php"><span class="material-symbols-sharp">mail</span><h3>Messages</h3></a>
            <a href="../settings/settings.php"><span class="material-symbols-sharp">settings</span><h3>Settings</h3></a>
            <a href="../../auth/logout.php"><span class="material-symbols-sharp">logout</span><h3>Logout</h3></a>
        </div>
    </aside>

    <main>
        <h1>Evacuation Centers</h1>
        
        <div class="form-container">
            <h3>Register New Center</h3>
            <form action="centers.php" method="POST" class="form-group-wrapper">
                
                <div class="grid-3-col">
                    <div class="input-box">
                        <p>Center Name</p>
                        <input type="text" name="center_name" placeholder="e.g. Brgy 1 Covered Court" required>
                    </div>
                    <div class="input-box">
                        <p>Capacity (Persons)</p>
                        <input type="number" name="capacity" placeholder="e.g. 500" required>
                    </div>
                    <div class="input-box">
                        <p>Status</p>
                        <select name="status" required>
                            <option value="Open">Open</option>
                            <option value="Full">Full</option>
                            <option value="Under Maintenance">Under Maintenance</option>
                        </select>
                    </div>
                </div>

                <div class="grid-2-col">
                    <div class="input-box">
                        <p>Contact Person</p>
                        <input type="text" name="contact_person" placeholder="Enter coordinator name">
                    </div>
                    <div class="input-box">
                        <p>Contact Number</p>
                        <input type="text" name="contact_number" placeholder="e.g. 09123456789">
                    </div>
                </div>

                <div class="grid-2-col">
                    <div class="input-box">
                        <p>Barangay</p>
                        <select name="barangay_name" id="barangay_dropdown" required>
                            <option value="" disabled selected>Loading Barangays...</option>
                        </select>
                    </div>
                </div>

                <button type="submit" name="create_center" class="btn-submit">Add Center</button>
            </form>
        </div>

        <div class="recent_alerts">
            <h2>Evacuation Centers List</h2>
            <table>
                <thead>
                    <tr>
                        <th>Center Details</th>
                        <th>Occupancy</th>
                        <th>Contact Info</th>
                        <th>Status</th>
                        <th class="text-center">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (!empty($centers)): ?>
                        <?php foreach($centers as $center): 
                            $status = htmlspecialchars($center['status'] ?? 'Open');
                            $statusColor = match($status) {
                                'Open' => 'success',
                                'Full' => 'danger',
                                'Under Maintenance' => 'warning',
                                default => 'text-light'
                            };
                        ?>
                        <tr>
                            <td>
                                <b><?= htmlspecialchars($center['center_name']) ?></b><br>
                                <small class="text-muted"><span class="material-symbols-sharp icon-sm">location_on</span> <?= htmlspecialchars($center['barangay_name']) ?></small>
                            </td>
                            <td>
                                <b><?= htmlspecialchars($center['current_individuals'] ?? 0) ?> / <?= htmlspecialchars($center['capacity']) ?> pax</b><br>
                                <small class="text-muted">Families: <?= htmlspecialchars($center['current_families'] ?? 0) ?></small>
                            </td>
                            <td>
                                <b><?= htmlspecialchars($center['contact_person'] ?? 'N/A') ?></b><br>
                                <small class="text-muted"><?= htmlspecialchars($center['contact_number'] ?? 'N/A') ?></small>
                            </td>
                            <td class="<?= $statusColor ?>"><b><?= $status ?></b></td>
                            <td class="table-actions">
                                
                                <button type="button" class="btn-icon edit" onclick="openEditModal(
                                    '<?= $center['center_id'] ?>', 
                                    '<?= htmlspecialchars(addslashes($center['center_name'])) ?>', 
                                    '<?= $center['capacity'] ?>', 
                                    '<?= htmlspecialchars(addslashes($center['barangay_name'])) ?>', 
                                    '<?= $center['status'] ?>',
                                    '<?= htmlspecialchars(addslashes($center['contact_person'] ?? '')) ?>',
                                    '<?= htmlspecialchars(addslashes($center['contact_number'] ?? '')) ?>'
                                )">
                                    <span class="material-symbols-sharp">edit</span>
                                </button>

                                <a href="centers.php?delete=<?= $center['center_id'] ?>" class="btn-icon delete" onclick="return confirm('Are you sure you want to remove this center?')">
                                    <span class="material-symbols-sharp">delete</span>
                                </a>

                            </td>
                        </tr>
                        <?php endforeach; ?>
                    <?php else: ?>
                        <tr>
                            <td colspan="5" class="empty-table">No evacuation centers registered yet.</td>
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
            <h2>Centers Summary</h2>
            <div class="stat">
                <span class="material-symbols-sharp">location_city</span>
                <div>
                    <h3>Total Centers</h3>
                    <p><b><?= count($centers) ?></b></p>
                </div>
            </div>
            
            <div class="chart-container custom-chart-box">
                <h3 class="mb-1">Center Status Overview</h3>
                <canvas id="centerStatusChart"></canvas>
            </div>
        </div>
    </div>
</div>

<div class="modal-overlay" id="updateModal" style="display: none;">
    <div class="modal-content">
        <h3 class="mb-1">Update Center Info</h3>
        <form action="centers.php" method="POST" class="form-group-wrapper text-left">
            <input type="hidden" name="center_id" id="update_center_id">
            
            <div class="grid-3-col">
                <div class="input-box">
                    <p>Center Name</p>
                    <input type="text" name="center_name" id="update_name" required>
                </div>
                <div class="input-box">
                    <p>Capacity</p>
                    <input type="number" name="capacity" id="update_capacity" required>
                </div>
                <div class="input-box">
                    <p>Status</p>
                    <select name="status" id="update_status" required>
                        <option value="Open">Open</option>
                        <option value="Full">Full</option>
                        <option value="Under Maintenance">Under Maintenance</option>
                    </select>
                </div>
            </div>

            <div class="grid-2-col">
                <div class="input-box">
                    <p>Contact Person</p>
                    <input type="text" name="contact_person" id="update_contact_person">
                </div>
                <div class="input-box">
                    <p>Contact Number</p>
                    <input type="text" name="contact_number" id="update_contact_number">
                </div>
            </div>
            
            <div class="grid-1-col">
                <div class="input-box">
                    <p>Barangay</p>
                    <select name="barangay_name" id="update_barangay" required>
                        <option value="" disabled selected>Loading Barangays...</option>
                    </select>
                </div>
            </div>
            
            <button type="submit" name="update_center" class="btn-submit" style="margin-top: 15px;">Save Changes</button>
            <button type="button" class="btn-submit btn-cancel" onclick="closeEditModal()">Cancel</button>
        </form>
    </div>
</div>

<script src="../../../public/js/script.js"></script>

<script>
    // JS LOCATION HANDLER
    document.addEventListener("DOMContentLoaded", function() {
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

    // Edit Modal Logic (Updated parameters to remove landmark)
    function openEditModal(id, centerName, capacity, barangayName, status, contactPerson, contactNumber) {
        document.getElementById('update_center_id').value = id;
        document.getElementById('update_name').value = centerName;
        document.getElementById('update_capacity').value = capacity;
        document.getElementById('update_status').value = status;
        document.getElementById('update_contact_person').value = contactPerson;
        document.getElementById('update_contact_number').value = contactNumber;
        
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
        const statusCtx = document.getElementById('centerStatusChart').getContext('2d');
        
        const statusLabels = <?= json_encode($statusData['labels'] ?? []) ?>;
        const statusValues = <?= json_encode($statusData['values'] ?? []) ?>;

        const getBgColor = (label) => {
            if(label === 'Open') return '#41f1b6'; 
            if(label === 'Under Maintenance') return '#ffbb55'; 
            if(label === 'Full') return '#ff7782'; 
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