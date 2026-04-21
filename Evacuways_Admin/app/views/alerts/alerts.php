<?php
session_start();
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Ensure path is correct for your server
require_once __DIR__ . "/../../controllers/AlertController.php";
$alertController = new AlertController();

$alertController->handleRequest();

$alerts = $alertController->index();
$chartData = $alertController->getMonthlyStats();
$typeData = $alertController->getTypeStats();
$adminCityCode = $alertController->getAdminCityCode(); 
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Emergency Alerts | Evacuways Admin</title>
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
            <a href="alerts.php" class="active"><span class="material-symbols-sharp">warning</span><h3>Emergency Alerts</h3></a>
            <a href="../vechicles/vehicles.php"><span class="material-symbols-sharp">airport_shuttle</span><h3>Evacuation Vehicles</h3></a>
            <a href="../centers/centers.php"><span class="material-symbols-sharp">location_city</span><h3>Evacuation Centers</h3></a>
            <a href="../families/families.php"><span class="material-symbols-sharp">groups</span><h3>Registered Families</h3></a>
            <a href="../checklists/checklists.php"><span class="material-symbols-sharp">assignment_turned_in</span><h3>Safety Checklists</h3></a>
            <a href="../volunteers/volunteers.php"><span class="material-symbols-sharp">volunteer_activism</span><h3>Volunteers</h3></a>
            <a href="../messages/messages.php"><span class="material-symbols-sharp">mail</span><h3>Messages</h3></a>
            <a href="../settings/settings.php"><span class="material-symbols-sharp">settings</span><h3>Settings</h3></a>
            <a href="../../auth/logout.php"><span class="material-symbols-sharp">logout</span><h3>Logout</h3></a>
        </div>
    </aside>

    <main>
        <h1>Emergency Alerts</h1>
        
        <div class="form-container">
            <h3>Post New Emergency Alert</h3>
            <form action="alerts.php" method="POST" class="form-group-wrapper" style="display: grid; gap: 1rem;">
                <input type="hidden" name="barangay_name" id="create_barangay_name_hidden">
                
                <div class="input-box">
                    <p>Alert Title</p>
                    <input type="text" name="title" placeholder="e.g. Typhoon Warning" required>
                </div>
                <div class="input-box">
                    <p>Message Details</p>
                    <textarea name="message" placeholder="Provide emergency instructions and details here..." required></textarea>
                </div>
                
                <div class="grid-3-col" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem;">
                    <div class="input-box">
                        <p>Alert Type</p>
                        <select name="alert_type">
                            <option value="Flood">Flood</option>
                            <option value="Typhoon">Typhoon</option>
                            <option value="Earthquake">Earthquake</option>
                            <option value="Fire">Fire</option>
                        </select>
                    </div>
                    <div class="input-box">
                        <p>Severity Level</p>
                        <select name="severity_level">
                            <option value="Critical">Critical</option>
                            <option value="Warning">Warning</option>
                            <option value="Information">Information</option>
                        </select>
                    </div>
                    <div class="input-box">
                        <p>Current Status</p>
                        <select name="status">
                            <option value="Active">Active</option>
                            <option value="Resolved">Resolved</option>
                        </select>
                    </div>
                    
                    <div class="input-box">
                        <p>Affected Barangay</p>
                        <select name="barangay_id" id="brgySelect" required>
                            <option value="">Loading Barangays...</option>
                        </select>
                    </div>
                </div>
                <button type="submit" name="create_alert" class="btn-submit">Post Alert</button>
            </form>
        </div>

        <div class="recent_alerts">
            <h2>Active Alerts List</h2>
            <table>
                <thead>
                    <tr>
                        <th>Title & Details</th>
                        <th>Barangay</th> 
                        <th>Type</th>
                        <th>Severity</th>
                        <th>Status</th>
                        <th style="text-align: center;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (!empty($alerts)): ?>
                        <?php foreach($alerts as $alert): 
                            $severity = htmlspecialchars($alert['severity_level']);
                            $colorClass = match($severity) {
                                'Critical' => 'danger',
                                'Warning' => 'warning',
                                'Information' => 'info',
                                default => 'text-light'
                            };
                            $status = htmlspecialchars($alert['status']);
                            $statusColor = ($status === 'Active') ? 'success' : 'text-light';
                            $brgyIdentifier = $alert['barangay_code'] ?? $alert['barangay_id'];
                        ?>
                        <tr>
                            <td>
                                <b><?= htmlspecialchars($alert['title']) ?></b><br>
                                <small style="color: var(--color-info-dark);"><?= htmlspecialchars($alert['message'] ?? '') ?></small>
                            </td>
                            <td><b><?= !empty($alert['barangay_name']) ? htmlspecialchars($alert['barangay_name']) : 'All Barangays' ?></b></td>
                            <td><?= htmlspecialchars($alert['alert_type']) ?></td>
                            <td class="<?= $colorClass ?>"><b><?= $severity ?></b></td>
                            <td class="<?= $statusColor ?>"><?= $status ?></td>
                            <td style="text-align: center; display: flex; justify-content: center; gap: 10px; align-items: center; padding: 1.2rem 0;">
                                <button type="button" class="btn-icon edit" 
                                    onclick="openEditModal('<?= $alert['alert_id'] ?>', 
                                    '<?= htmlspecialchars(addslashes($alert['title'])) ?>', 
                                    '<?= htmlspecialchars(addslashes($alert['message'] ?? '')) ?>', 
                                    '<?= $alert['alert_type'] ?>', 
                                    '<?= $alert['severity_level'] ?>', 
                                    '<?= $alert['status'] ?>', 
                                    '<?= $brgyIdentifier ?>')">
                                    <span class="material-symbols-sharp">edit</span>
                                </button>
                                <a href="alerts.php?delete=<?= $alert['alert_id'] ?>" class="btn-icon delete" onclick="return confirm('Are you sure you want to delete this alert?')">
                                    <span class="material-symbols-sharp">delete</span>
                                </a>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    <?php else: ?>
                        <tr><td colspan="6" style="text-align:center; padding: 2rem;">No alerts found.</td></tr> 
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
            <h2>Alert Summary</h2>
            <div class="stat">
                <span class="material-symbols-sharp">notifications_active</span>
                <div>
                    <h3>Total Logged</h3>
                    <p><b><?= count($alerts) ?></b></p>
                </div>
            </div>
            
            <div class="chart-container" style="margin-top: 2rem; background: var(--color-white); padding: 1rem; border-radius: var(--card-border-radius); box-shadow: var(--box-shadow);">
                <canvas id="monthlyAlertsChart"></canvas>
            </div>
            
            <div class="chart-container" style="margin-top: 1.5rem; background: var(--color-white); padding: 1rem; border-radius: var(--card-border-radius); box-shadow: var(--box-shadow);">
                <canvas id="alertTypeChart"></canvas>
            </div>
        </div>
    </div>
</div>

<div class="modal-overlay" id="updateModal" style="display: none;">
    <div class="modal-content">
        <h3>Update Alert</h3>
        <form action="alerts.php" method="POST" style="display: grid; gap: 1rem; text-align: left;">
            <input type="hidden" name="alert_id" id="update_alert_id">
            <input type="hidden" name="barangay_name" id="update_barangay_name_hidden">

            <div class="input-box">
                <p>Alert Title</p>
                <input type="text" name="title" id="update_title" required>
            </div>
            <div class="input-box">
                <p>Message Details</p>
                <textarea name="message" id="update_message" required></textarea>
            </div>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem;">
                <div class="input-box">
                    <p>Alert Type</p>
                    <select name="alert_type" id="update_type">
                        <option value="Flood">Flood</option>
                        <option value="Typhoon">Typhoon</option>
                        <option value="Earthquake">Earthquake</option>
                        <option value="Fire">Fire</option>
                    </select>
                </div>
                <div class="input-box">
                    <p>Severity</p>
                    <select name="severity_level" id="update_severity">
                        <option value="Critical">Critical</option>
                        <option value="Warning">Warning</option>
                        <option value="Information">Information</option>
                    </select>
                </div>
            </div>

            <div class="input-box">
                <p>Affected Barangay</p>
                <select name="barangay_id" id="update_brgySelect" required>
                    <option value="">Loading Barangays...</option>
                </select>
            </div>

            <div class="input-box">
                <p>Status</p>
                <select name="status" id="update_status">
                    <option value="Active">Active</option>
                    <option value="Resolved">Resolved</option>
                </select>
            </div>
            <button type="submit" name="update_alert" class="btn-submit">Save Changes</button>
            <button type="button" class="btn-submit btn-cancel" onclick="closeEditModal()">Cancel</button>
        </form>
    </div>
</div>

<script src="../../../public/js/script.js"></script>
<script src="../../../public/js/location_handler.js"></script>

<script>
    /**
     * SYNC LOGIC: Captures the "Text" of the selected Barangay option
     */
    function syncBarangayName(selectId, hiddenId) {
        const selectEl = document.getElementById(selectId);
        const hiddenEl = document.getElementById(hiddenId);
        if (selectEl.selectedIndex >= 0) {
            hiddenEl.value = selectEl.options[selectEl.selectedIndex].text;
        }
    }

    document.addEventListener("DOMContentLoaded", () => {
        const adminCity = "<?= $adminCityCode ?>"; 
        
        if (typeof LocationHandler !== 'undefined' && adminCity) {
            LocationHandler.loadBarangays(adminCity, 'brgySelect');
            LocationHandler.loadBarangays(adminCity, 'update_brgySelect');
        }

        // Listen for changes in the dropdowns
        document.getElementById('brgySelect').addEventListener('change', () => syncBarangayName('brgySelect', 'create_barangay_name_hidden'));
        document.getElementById('update_brgySelect').addEventListener('change', () => syncBarangayName('update_brgySelect', 'update_barangay_name_hidden'));

        // --- CHARTS ---
        const ctx = document.getElementById('monthlyAlertsChart').getContext('2d');
        new Chart(ctx, {
            type: 'line', 
            data: {
                labels: <?= json_encode($chartData['labels']) ?>,
                datasets: [{
                    label: 'Alerts',
                    data: <?= json_encode($chartData['values']) ?>,
                    borderColor: '#ff7782',
                    tension: 0.4,
                    fill: true,
                    backgroundColor: 'rgba(255, 119, 130, 0.1)'
                }]
            }
        });

        const typeCtx = document.getElementById('alertTypeChart').getContext('2d');
        new Chart(typeCtx, {
            type: 'doughnut',
            data: {
                labels: <?= json_encode($typeData['labels']) ?>,
                datasets: [{
                    data: <?= json_encode($typeData['values']) ?>,
                    backgroundColor: ['#7380ec', '#ffbb55', '#ff7782', '#41f1b6']
                }]
            },
            options: { cutout: '70%' }
        });
    });

    function openEditModal(id, title, msg, type, sev, stat, brgy) {
        document.getElementById('update_alert_id').value = id;
        document.getElementById('update_title').value = title;
        document.getElementById('update_message').value = msg;
        document.getElementById('update_type').value = type;
        document.getElementById('update_severity').value = sev;
        document.getElementById('update_status').value = stat;

        const brgyDropdown = document.getElementById('update_brgySelect');
        
        const trySelect = () => {
            if (brgyDropdown.options.length > 1) {
                brgyDropdown.value = brgy;
                // Sync the name hidden field immediately after selection
                syncBarangayName('update_brgySelect', 'update_barangay_name_hidden');
            } else {
                setTimeout(trySelect, 100);
            }
        };
        trySelect();

        document.getElementById('updateModal').style.display = 'flex';
    }

    function closeEditModal() {
        document.getElementById('updateModal').style.display = 'none';
    }
</script>
</body>
</html>