<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . "/../../../app/controllers/FamilyController.php";
$familyController = new FamilyController();

$familyController->handleRequest();
$families = $familyController->index();

// Fetch data for the dropdowns
$centers = $familyController->getCenters();
$vehicles = $familyController->getVehicles();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registered Families | Evacuways Admin</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Sharp" />
    <link rel="stylesheet" href="../../../public/css/style.css?v=<?php echo time(); ?>">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
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
            <a href="../centers/centers.php"><span class="material-symbols-sharp">location_city</span><h3>Evacuation Centers</h3></a>
            <a href="families.php" class="active"><span class="material-symbols-sharp">groups</span><h3>Registered Families</h3></a>
            <a href="../checklists/checklists.php"><span class="material-symbols-sharp">assignment_turned_in</span><h3>Safety Checklists</h3></a>
            <a href="../volunteers/volunteers.php"><span class="material-symbols-sharp">volunteer_activism</span><h3>Volunteers</h3></a>
            <a href="../messages/messages.php"><span class="material-symbols-sharp">mail</span><h3>Messages</h3></a>
            <a href="../settings/settings.php"><span class="material-symbols-sharp">settings</span><h3>Settings</h3></a>
            <a href="../../auth/logout.php"><span class="material-symbols-sharp">logout</span><h3>Logout</h3></a>
        </div>
    </aside>

    <main>
        <h1>Registered Families</h1>
        
        <div id="familyMap" style="height: 350px; width: 100%; border-radius: var(--border-radius-1); margin: 1.5rem 0; z-index: 1;"></div>
        
        <div class="form-container" style="margin-bottom: 2rem;">
            <h3>Register New Family Head</h3>
            <form action="families.php" method="POST" class="form-group-wrapper">
                <div class="grid-3-col">
                    <div class="input-box">
                        <p>First Name</p>
                        <input type="text" name="first_name" placeholder="e.g. Juan" required>
                    </div>
                    <div class="input-box">
                        <p>Last Name</p>
                        <input type="text" name="last_name" placeholder="e.g. Dela Cruz" required>
                    </div>
                    <div class="input-box">
                        <p>Contact Number</p>
                        <input type="text" name="contact_number" placeholder="0912..." required>
                    </div>
                </div>

                <div class="grid-3-col">
                    <div class="input-box">
                        <p>Total Headcount</p>
                        <input type="number" name="headcount" value="1" min="1" required>
                    </div>
                    <div class="input-box">
                        <p>Missing Members</p>
                        <input type="number" name="missing_count" value="0">
                    </div>
                    <div class="input-box">
                        <p>Barangay</p>
                        <select name="barangay_code" id="barangay_dropdown" required>
                            <option value="" disabled selected>Loading...</option>
                        </select>
                    </div>
                </div>

                <button type="submit" name="create_family" class="btn-submit">Add Family</button>
            </form>
        </div>

        <div class="recent_alerts">
            <div style="margin-bottom: 1rem;">
                <h2>Families List</h2>
            </div>

            <table>
                <thead>
                    <tr>
                        <th>Family Details</th>
                        <th>Headcount</th>
                        <th>Assignments</th> 
                        <th>Status</th>
                        <th class="text-center">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (!empty($families)): ?>
                        <?php foreach($families as $family): 
                            $status = $family['rescue_status'] ?? 'Pending Rescue';
                            $statusColor = match($status) {
                                'Rescued' => 'success',
                                'In Transit' => 'warning',
                                default => 'danger'
                            };
                        ?>
                        <tr>
                            <td>
                                <b><?= htmlspecialchars($family['first_name'] . ' ' . $family['last_name']) ?></b><br>
                                <small class="text-muted"><?= htmlspecialchars($family['contact_number']) ?></small><br>
                                <small class="text-muted"><?= htmlspecialchars($family['barangay_name'] ?? 'Unassigned') ?></small>
                            </td>
                            <td>
                                <b>Total: <?= $family['headcount'] ?></b><br>
                                <small class="<?= $family['missing_count'] > 0 ? 'danger' : 'text-muted' ?>">
                                    Missing: <?= $family['missing_count'] ?>
                                </small>
                            </td>
                            <td>
                                <small><b>Vehicle:</b> <?= htmlspecialchars($family['plate_number'] ?? 'None') ?></small><br>
                                <small><b>Center:</b> <?= htmlspecialchars($family['center_name'] ?? 'None') ?></small>
                            </td>
                            <td class="<?= $statusColor ?>"><b><?= $status ?></b></td>
                            <td class="table-actions">
                                <button class="btn-icon edit" onclick="openEditModal('<?= $family['user_id'] ?>', '<?= $status ?>', '<?= $family['missing_count'] ?>', '<?= $family['assigned_vehicle_id'] ?>', '<?= $family['assigned_center_id'] ?>')">
                                    <span class="material-symbols-sharp">edit</span>
                                </button>
                                <a href="families.php?delete=<?= $family['user_id'] ?>" class="btn-icon delete" onclick="return confirm('Remove this family?')">
                                    <span class="material-symbols-sharp">delete</span>
                                </a>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    <?php else: ?>
                        <tr><td colspan="5" class="text-center">No families registered.</td></tr>
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
            <h2>Summary</h2>
            <div class="stat">
                <span class="material-symbols-sharp">groups</span>
                <div>
                    <h3>Total Families</h3>
                    <p><b><?= count($families) ?></b></p>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal-overlay" id="updateModal" style="display: none;">
    <div class="modal-content">
        <h3>Update Family Status</h3>
        <form action="families.php" method="POST" class="form-group-wrapper">
            <input type="hidden" name="user_id" id="update_user_id">
            <div class="grid-2-col">
                <div class="input-box">
                    <p>Rescue Status</p>
                    <select name="rescue_status" id="update_status">
                        <option value="Pending Rescue">Pending Rescue</option>
                        <option value="In Transit">In Transit</option>
                        <option value="Rescued">Rescued</option>
                    </select>
                </div>
                <div class="input-box">
                    <p>Missing Members</p>
                    <input type="number" name="missing_count" id="update_missing">
                </div>
            </div>
            <div class="grid-2-col">
                <div class="input-box">
                    <p>Assign Vehicle</p>
                    <select name="assigned_vehicle_id" id="update_vehicle">
                        <option value="">-- None --</option>
                        <?php foreach($vehicles as $v): ?>
                            <option value="<?= $v['vehicle_id'] ?>"><?= $v['plate_number'] ?> (<?= $v['vehicle_type'] ?>)</option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="input-box">
                    <p>Assign Center</p>
                    <select name="assigned_center_id" id="update_center">
                        <option value="">-- None --</option>
                        <?php foreach($centers as $c): ?>
                            <option value="<?= $c['center_id'] ?>"><?= $c['center_name'] ?></option>
                        <?php endforeach; ?>
                    </select>
                </div>
            </div>
            <button type="submit" name="update_family" class="btn-submit">Save Changes</button>
            <button type="button" class="btn-submit btn-cancel" onclick="closeEditModal()">Cancel</button>
        </form>
    </div>
</div>

<script src="../../../public/js/script.js"></script>

<script>
    // MODAL HANDLERS
    function openEditModal(id, status, missing, vehicleId, centerId) {
        document.getElementById('update_user_id').value = id;
        document.getElementById('update_status').value = status;
        document.getElementById('update_missing').value = missing;
        document.getElementById('update_vehicle').value = vehicleId || '';
        document.getElementById('update_center').value = centerId || '';
        document.getElementById('updateModal').style.display = 'flex';
    }

    function closeEditModal() {
        document.getElementById('updateModal').style.display = 'none';
    }

    // PSGC DATA LOADER
    document.addEventListener("DOMContentLoaded", function() {
        const drop = document.getElementById('barangay_dropdown');
        fetch(`https://psgc.gitlab.io/api/cities-municipalities/064501000/barangays/`)
            .then(res => res.json())
            .then(data => {
                if (!drop) return;
                drop.innerHTML = '<option value="" disabled selected>Select Barangay</option>';
                data.sort((a,b) => a.name.localeCompare(b.name)).forEach(b => {
                    const opt = document.createElement('option');
                    opt.value = b.code;
                    opt.textContent = b.name;
                    drop.appendChild(opt);
                });
            });
    });

    // LEAFLET MAP
    document.addEventListener("DOMContentLoaded", function() {
        const map = L.map('familyMap').setView([10.6762, 122.9568], 13);
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);
        
        const fams = <?= json_encode($families ?? []) ?>;
        fams.forEach(f => {
            if (f.latitude && f.longitude) {
                L.marker([f.latitude, f.longitude]).addTo(map)
                    .bindPopup(`<b>${f.first_name} ${f.last_name}</b><br>Status: ${f.rescue_status}`);
            }
        });
    });
</script>
</body>
</html>