<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once __DIR__ . "/../../../app/controllers/ChecklistController.php";
$controller = new ChecklistController();

$controller->handleRequest();

$searchTerm = $_GET['search'] ?? '';
$checklists = $controller->index($searchTerm);
$completions = $controller->stats(); 
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Safety Checklists | Evacuways Admin</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Sharp" />
    <link rel="stylesheet" href="../../../public/css/style.css?v=<?php echo time(); ?>">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        .table-actions { display: flex; gap: 10px; justify-content: center; }
        .role-badge { padding: 4px 10px; border-radius: 12px; font-size: 0.75rem; font-weight: 600; }
        .role-Family { background: rgba(71, 157, 234, 0.1); color: #479dea; }
        .role-Volunteer { background: rgba(255, 187, 85, 0.1); color: #ffbb55; }
        .role-Driver { background: rgba(115, 128, 236, 0.1); color: #7380ec; }
        .role-Center { background: rgba(255, 119, 130, 0.1); color: #ff7782; }
        
        #items_list table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        #items_list th, #items_list td { padding: 12px; border-bottom: 1px solid var(--color-light); text-align: left; }
        #items_list tr:hover { background: var(--color-light); }
    </style>
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
            <a href="../sos/sos.php"><span class="material-symbols-sharp">emergency</span><h3>Emergency SOS</h3></a>
            <a href="../vechicles/vehicles.php"><span class="material-symbols-sharp">airport_shuttle</span><h3>Evacuation Vehicles</h3></a>
            <a href="../centers/centers.php"><span class="material-symbols-sharp">location_city</span><h3>Evacuation Centers</h3></a>
            <a href="../families/families.php"><span class="material-symbols-sharp">groups</span><h3>Registered Families</h3></a>
            <a href="checklists.php" class="active"><span class="material-symbols-sharp">assignment_turned_in</span><h3>Safety Checklists</h3></a>
            <a href="../volunteers/volunteers.php"><span class="material-symbols-sharp">volunteer_activism</span><h3>Volunteers</h3></a>
            <a href="../messages/messages.php"><span class="material-symbols-sharp">mail</span><h3>Messages</h3></a>
            <a href="../settings/settings.php"><span class="material-symbols-sharp">settings</span><h3>Settings</h3></a>
            <a href="../../auth/logout.php"><span class="material-symbols-sharp">logout</span><h3>Logout</h3></a>
        </div>
    </aside>

    <main>
        <h1>Safety Protocols & Checklists</h1>
        
        <?php if(isset($_GET['success'])): ?>
            <div class="alert success mb-1" style="padding: 1rem; border-radius: 10px; background: rgba(76, 175, 80, 0.1); color: var(--color-success); display: flex; align-items: center; gap: 10px;">
                <span class="material-symbols-sharp">check_circle</span>
                <?= htmlspecialchars($_GET['success']) ?>
            </div>
        <?php endif; ?>

        <div class="form-container">
            <h3>Define New Safety Protocol</h3>
            <form action="checklists.php" method="POST" class="form-group-wrapper">
                <div class="grid-2-col">
                    <div class="input-box">
                        <p>Protocol Name</p>
                        <input type="text" name="checklist_name" placeholder="e.g. Typhoon Preparedness" required>
                    </div>
                    <div class="input-box">
                        <p>Assign To Role</p>
                        <select name="target_role" required>
                            <option value="Family">Families / Citizens</option>
                            <option value="Volunteer">Rescue Volunteers</option>
                            <option value="Driver">Vehicle Drivers</option>
                            <option value="Center">Center Officials</option>
                        </select>
                    </div>
                </div>

                <div class="input-box">
                    <p>Brief Description / Instruction</p>
                    <textarea name="description" placeholder="Short summary of what this checklist aims to achieve..." style="width: 100%; border-radius: 8px; padding: 10px; background: var(--color-background); color: var(--color-dark); border: 1px solid var(--color-light);"></textarea>
                </div>

                <div class="input-box">
                    <p>Special Priorities (Checked items will show specific icons)</p>
                    <div style="display: flex; gap: 20px; padding-top: 5px;">
                        <label style="display: flex; align-items: center; gap: 8px;"><input type="checkbox" name="for_children"> Children</label>
                        <label style="display: flex; align-items: center; gap: 8px;"><input type="checkbox" name="for_elderly"> Elderly</label>
                        <label style="display: flex; align-items: center; gap: 8px;"><input type="checkbox" name="for_pwd"> PWDs</label>
                    </div>
                </div>

                <button type="submit" name="create_checklist" class="btn-submit">Add Protocol</button>
            </form>
        </div>

        <div class="recent_alerts">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 0.8rem;">
                <h2>Safety Protocols List</h2>
                <div class="search-box" style="margin-bottom: 0;">
                    <input type="text" id="listingSearch" placeholder="Filter protocols..." value="<?= htmlspecialchars($searchTerm) ?>" onkeyup="handleSearch(event)" style="padding: 10px; border-radius: 8px; border: 1px solid var(--color-light);">
                </div>
            </div>
            <table>
                <thead>
                    <tr>
                        <th>Protocol Details</th>
                        <th>Target Audience</th>
                        <th>Priority</th>
                        <th class="text-center">Steps</th>
                        <th class="text-center">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (!empty($checklists)): ?>
                        <?php foreach($checklists as $checklist): 
                            $role = $checklist['target_role'] ?? 'Family';
                        ?>
                        <tr>
                            <td>
                                <b><?= htmlspecialchars($checklist['checklist_name']) ?></b><br>
                                <small class="text-muted"><?= htmlspecialchars($checklist['description'] ?? 'No description') ?></small>
                            </td>
                            <td>
                                <span class="role-badge role-<?= $role ?>"><?= $role ?></span>
                            </td>
                            <td>
                                <div style="display: flex; gap: 5px;">
                                    <?php if($checklist['for_children']): ?><span class="material-symbols-sharp" style="font-size: 1.2rem;" title="Children">child_care</span><?php endif; ?>
                                    <?php if($checklist['for_elderly']): ?><span class="material-symbols-sharp" style="font-size: 1.2rem;" title="Elderly">elderly</span><?php endif; ?>
                                    <?php if($checklist['for_pwd']): ?><span class="material-symbols-sharp" style="font-size: 1.2rem;" title="PWD">accessible_forward</span><?php endif; ?>
                                </div>
                            </td>
                            <td class="text-center">
                                <b><?= $checklist['item_count'] ?></b>
                            </td>
                            <td class="table-actions">
                                <button type="button" class="btn-icon edit-btn" title="Edit Metadata" 
                                        data-checklist='<?= htmlspecialchars(json_encode($checklist), ENT_QUOTES, 'UTF-8') ?>'>
                                    <span class="material-symbols-sharp">edit</span>
                                </button>
                                <button type="button" class="btn-icon steps-btn" title="Manage Steps" 
                                        data-id="<?= $checklist['checklist_id'] ?>"
                                        data-name="<?= htmlspecialchars($checklist['checklist_name'] ?? '') ?>">
                                    <span class="material-symbols-sharp">list_alt</span>
                                </button>
                                <a href="checklists.php?delete_checklist=<?= $checklist['checklist_id'] ?>" class="btn-icon delete" onclick="return confirm('Delete this entire protocol?')">
                                    <span class="material-symbols-sharp">delete</span>
                                </a>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    <?php else: ?>
                        <tr>
                            <td colspan="5" class="empty-table">No safety protocols found.</td>
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
            <h2>Safety Summary</h2>
            <div class="stat">
                <span class="material-symbols-sharp">assignment_turned_in</span>
                <div>
                    <h3>Total Protocols</h3>
                    <p><b><?= count($checklists) ?></b></p>
                </div>
            </div>
            
            <div class="chart-container custom-chart-box">
                <h3 class="mb-1">Protocol Distribution</h3>
                <div style="height: 200px;">
                    <canvas id="categoryChart"></canvas>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Modal: Update Protocol Metadata -->
<div class="modal-overlay" id="updateProtocolModal" style="display: none;">
    <div class="modal-content">
        <h3 class="mb-1">Edit Protocol Metadata</h3>
        <form action="checklists.php" method="POST" class="form-group-wrapper text-left">
            <input type="hidden" name="update_checklist_id" id="edit_proto_id">
            
            <div class="input-box">
                <p>Protocol Name</p>
                <input type="text" name="checklist_name" id="edit_proto_name" required>
            </div>

            <div class="input-box">
                <p>Description</p>
                <textarea name="description" id="edit_proto_desc" style="width: 100%; height: 80px;"></textarea>
            </div>

            <div class="grid-2-col">
                <div class="input-box">
                    <p>Target Role</p>
                    <select name="target_role" id="edit_proto_role">
                        <option value="Family">Families / Citizens</option>
                        <option value="Volunteer">Rescue Volunteers</option>
                        <option value="Driver">Vehicle Drivers</option>
                        <option value="Center">Center Officials</option>
                    </select>
                </div>
                <div class="input-box">
                    <p>Priorities</p>
                    <div style="display: flex; flex-wrap: wrap; gap: 10px; padding-top: 5px;">
                        <label><input type="checkbox" name="for_children" id="edit_proto_children"> Child</label>
                        <label><input type="checkbox" name="for_elderly" id="edit_proto_elderly"> Elderly</label>
                        <label><input type="checkbox" name="for_pwd" id="edit_proto_pwd"> PWD</label>
                    </div>
                </div>
            </div>
            
            <button type="submit" name="edit_checklist" class="btn-submit" style="margin-top: 15px;">Save Changes</button>
            <button type="button" class="btn-submit btn-cancel" onclick="closeEditModal()">Cancel</button>
        </form>
    </div>
</div>

<!-- Modal: Manage Checklist Items (Steps) -->
<div class="modal-overlay" id="manageItemsModal" style="display: none;">
    <div class="modal-content" style="max-width: 800px; max-height: 90vh; overflow: auto;">
        <h3 class="mb-1">Protocol Steps: <span id="proto_name_title" class="text-primary"></span></h3>
        
        <div style="background: rgba(115, 128, 236, 0.05); padding: 15px; border-radius: 10px; margin-bottom: 20px;">
            <h4>Add New Step</h4>
            <form action="checklists.php" method="POST" style="display: flex; gap: 10px; margin-top: 10px;">
                <input type="hidden" name="checklist_id" id="items_proto_id">
                <input type="text" name="item_description" placeholder="Enter safety instruction or requirement..." required style="flex-grow: 1; padding: 10px; border-radius: 8px; border: 1px solid var(--color-light);">
                <button type="submit" name="add_item" class="btn-submit" style="width: auto; margin: 0;">Add Step</button>
            </form>
        </div>

        <div id="items_list">
            <!-- Items will be loaded here via JS -->
            <p class="text-muted">Loading steps...</p>
        </div>

        <button type="button" class="btn-submit btn-cancel" style="margin-top: 20px;" onclick="closeItemsModal()">Close Manager</button>
    </div>
</div>

<script src="../../../public/js/script.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        // --- SEARCH HANDLER ---
        const searchInput = document.querySelector('input[type="text"][placeholder="Search safety protocols..."]');
        if (searchInput) {
            searchInput.addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    window.location.href = 'checklists.php?search=' + encodeURIComponent(e.target.value);
                }
            });
        }

        // --- EDIT MODAL HANDLER ---
        const editButtons = document.querySelectorAll('.edit-btn');
        const editModal = document.getElementById('updateProtocolModal');
        
        editButtons.forEach(btn => {
            btn.addEventListener('click', function() {
                const data = JSON.parse(this.getAttribute('data-checklist'));
                console.log("Opening Edit Modal", data);
                
                document.getElementById('edit_proto_id').value = data.checklist_id;
                document.getElementById('edit_proto_name').value = data.checklist_name;
                document.getElementById('edit_proto_desc').value = data.description || '';
                document.getElementById('edit_proto_role').value = data.target_role || 'Family';
                document.getElementById('edit_proto_children').checked = data.for_children == 1;
                document.getElementById('edit_proto_elderly').checked = data.for_elderly == 1;
                document.getElementById('edit_proto_pwd').checked = data.for_pwd == 1;
                
                editModal.style.display = 'flex';
                editModal.style.zIndex = '999999';
            });
        });

        // --- STEPS MODAL HANDLER ---
        const stepsButtons = document.querySelectorAll('.steps-btn');
        const stepsModal = document.getElementById('manageItemsModal');
        const listDiv = document.getElementById('items_list');
        
        stepsButtons.forEach(btn => {
            btn.addEventListener('click', async function() {
                const id = this.getAttribute('data-id');
                const name = this.getAttribute('data-name');
                console.log("Opening Steps Modal", id, name);
                
                document.getElementById('proto_name_title').textContent = name;
                document.getElementById('items_proto_id').value = id;
                
                stepsModal.style.display = 'flex';
                stepsModal.style.zIndex = '999999';
                listDiv.innerHTML = '<p class="text-muted">Loading steps...</p>';

                try {
                    const response = await fetch(`../../../api/checklists/get_items.php?id=${id}`);
                    const items = await response.json();
                    
                    if (items.error) {
                        listDiv.innerHTML = `<p class="danger">${items.error}</p>`;
                        return;
                    }

                    if (items.length === 0) {
                        listDiv.innerHTML = '<p class="text-muted text-center" style="padding: 20px;">No steps defined for this protocol yet.</p>';
                    } else {
                        let html = '<table><thead><tr><th>Step Description</th><th class="text-center">Actions</th></tr></thead><tbody>';
                        items.forEach(item => {
                            const descSafe = item.item_description.replace(/"/g, '&quot;');
                            html += `
                                <tr>
                                    <td>
                                        <form action="checklists.php" method="POST" id="form-item-${item.item_id}" style="display:flex; gap: 5px; width: 100%;">
                                            <input type="hidden" name="update_item_id" value="${item.item_id}">
                                            <input type="text" name="item_description" value="${descSafe}" style="width: 100%; border:none; background:transparent; font-size: 0.9rem; color: var(--color-dark);">
                                        </form>
                                    </td>
                                    <td class="table-actions">
                                        <button type="submit" form="form-item-${item.item_id}" class="btn-icon success" title="Save Change">
                                            <span class="material-symbols-sharp">check</span>
                                        </button>
                                        <a href="checklists.php?delete_item=${item.item_id}" class="btn-icon delete" onclick="return confirm('Delete this step?')">
                                            <span class="material-symbols-sharp">delete</span>
                                        </a>
                                    </td>
                                </tr>
                            `;
                        });
                        html += '</tbody></table>';
                        listDiv.innerHTML = html;
                    }
                } catch (e) {
                    console.error("Fetch Error:", e);
                    listDiv.innerHTML = '<p class="danger">Error loading steps. Check database connection.</p>';
                }
            });
        });

        // --- CHART INTEGRATION ---
        const chartCanvas = document.getElementById('roleDistributionChart');
        if (chartCanvas) {
            const ctx = chartCanvas.getContext('2d');
            const roles = {};
            <?php foreach($checklists as $c): ?>
                roles['<?= addslashes($c['target_role'] ?? 'General') ?>'] = (roles['<?= addslashes($c['target_role'] ?? 'General') ?>'] || 0) + 1;
            <?php endforeach; ?>

            new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: Object.keys(roles),
                    datasets: [{
                        data: Object.values(roles),
                        backgroundColor: ['#7380ec', '#41f1b6', '#ffbb55', '#ff7782'],
                        borderWidth: 0
                    }]
                },
                options: { responsive: true, cutout: '70%'}
            });
        }
    });

    // --- GLOBAL MODAL CLOSERS ---
    function closeEditModal() { document.getElementById('updateProtocolModal').style.display = 'none'; }
    function closeItemsModal() { document.getElementById('manageItemsModal').style.display = 'none'; }

</script>
</body>
</html>
