<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Adjust this path if necessary to point to your controller
require_once __DIR__ . "/../../../app/controllers/MessageController.php";
$messageController = new MessageController();
$messageController->handleRequest();

// Using ID 1 as fallback based on your evacuways_admins table
$adminId = $_SESSION['admin_id'] ?? 1; 

$searchQuery = $_GET['search'] ?? '';
$contacts = $messageController->getContacts($searchQuery);

$activeUserId = $_GET['user_id'] ?? ($contacts[0]['user_id'] ?? null);
$messages = $activeUserId ? $messageController->getChat($adminId, $activeUserId) : [];

$activeUser = null;
foreach ($contacts as $contact) {
    if ($contact['user_id'] == $activeUserId) {
        $activeUser = $contact;
        break;
    }
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Messages | Evacuways Admin</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Sharp" />
    <link rel="stylesheet" href="../../../public/css/style.css?v=<?php echo time(); ?>">
    <style>
        .messenger-container { display: flex; height: 75vh; background: var(--color-white, #ffffff); border-radius: var(--border-radius-1, 8px); box-shadow: var(--box-shadow, 0 2px 10px rgba(0,0,0,0.1)); overflow: hidden; margin-top: 1.5rem; }
        .contact-list { width: 35%; border-right: 1px solid var(--color-light, #f4f4f4); display: flex; flex-direction: column; }
        .search-bar { padding: 1rem; border-bottom: 1px solid var(--color-light, #f4f4f4); }
        .search-bar input { width: 100%; padding: 0.8rem; border-radius: var(--border-radius-1, 8px); border: 1px solid var(--color-info-light, #dce1eb); background: var(--color-background, #f6f6f9); color: var(--color-dark, #363949); }
        .contacts { overflow-y: auto; flex: 1; }
        .contact-item { padding: 1rem; border-bottom: 1px solid var(--color-light, #f4f4f4); cursor: pointer; display: flex; align-items: center; gap: 1rem; color: var(--color-dark, #363949); text-decoration: none; transition: all 0.3s ease; }
        .contact-item:hover, .contact-item.active { background: var(--color-light, #e0e0e0); }
        .chat-window { width: 65%; display: flex; flex-direction: column; }
        .chat-header { padding: 1rem; border-bottom: 1px solid var(--color-light, #f4f4f4); display: flex; align-items: center; }
        .chat-messages { flex: 1; padding: 1rem; overflow-y: auto; display: flex; flex-direction: column; gap: 1rem; background: var(--color-background, #f6f6f9); }
        .message { max-width: 60%; padding: 0.8rem 1rem; border-radius: var(--border-radius-1, 8px); word-wrap: break-word; }
        
        .message.sent { align-self: flex-end; background: var(--color-primary, #007bff); color: white; border-bottom-right-radius: 0; }
        .message.received { align-self: flex-start; background: var(--color-white, #ffffff); border: 1px solid var(--color-light, #ccc); color: var(--color-dark, #333); border-bottom-left-radius: 0; }
        
        .message img { max-width: 100%; border-radius: var(--border-radius-1, 8px); margin-top: 0.5rem; }
        .chat-input { padding: 1rem; border-top: 1px solid var(--color-light, #f4f4f4); display: flex; gap: 1rem; align-items: center; }
        .chat-input input[type="text"] { flex: 1; padding: 0.8rem; border-radius: var(--border-radius-1, 8px); border: 1px solid var(--color-info-light, #dce1eb); background: var(--color-background, #f6f6f9); color: var(--color-dark, #363949); }
        
        /* Updated File Upload CSS */
        .file-upload-wrapper { position: relative; cursor: pointer; display: flex; align-items: center; }
        .file-upload-wrapper input[type="file"] { position: absolute; opacity: 0; width: 0; height: 0; z-index: -1; }
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
        </div>
        <div class="sidebar">
            <a href="../../views/dashboard/dashboard.php"><span class="material-symbols-sharp">grid_view</span><h3>Dashboard</h3></a>
            <a href="../alerts/alerts.php"><span class="material-symbols-sharp">warning</span><h3>Emergency Alerts</h3></a>
            <a href="../vechicles/vehicles.php"><span class="material-symbols-sharp">airport_shuttle</span><h3>Evacuation Vehicles</h3></a>
            <a href="../centers/centers.php"><span class="material-symbols-sharp">location_city</span><h3>Evacuation Centers</h3></a>
            <a href="../families/families.php"><span class="material-symbols-sharp">groups</span><h3>Registered Families</h3></a>
            <a href="../volunteers/volunteers.php"><span class="material-symbols-sharp">volunteer_activism</span><h3>Volunteers</h3></a>
            <a href="messages.php" class="active"><span class="material-symbols-sharp">mail</span><h3>Messages</h3></a>
            <a href="../settings/settings.php"><span class="material-symbols-sharp">settings</span><h3>Settings</h3></a>
            <a href="../../auth/logout.php"><span class="material-symbols-sharp">logout</span><h3>Logout</h3></a>
        </div>
    </aside>

    <main style="width: 100%;">
        <h1>Messages</h1>

        <?php if(isset($_GET['error']) && $_GET['error'] == 'invalid_file'): ?>
            <div style="color: var(--color-danger, red); padding: 1rem; background: #ffe6e6; border-radius: 5px; margin-top: 1rem;">
                Error: Only JPEG images are allowed.
            </div>
        <?php endif; ?>

        <div class="messenger-container">
            <div class="contact-list">
                <div class="search-bar">
                    <form action="messages.php" method="GET">
                        <input type="text" name="search" placeholder="Search users..." value="<?= htmlspecialchars($searchQuery) ?>">
                    </form>
                </div>
                <div class="contacts">
                    <?php foreach($contacts as $contact): ?>
                        <a href="messages.php?user_id=<?= $contact['user_id'] ?>" class="contact-item <?= ($contact['user_id'] == $activeUserId) ? 'active' : '' ?>">
                            <span class="material-symbols-sharp">account_circle</span>
                            <div>
                                <h4><?= htmlspecialchars($contact['first_name'] . ' ' . $contact['last_name']) ?></h4>
                                <small class="text-muted"><?= htmlspecialchars($contact['contact_number'] ?? 'No Number') ?></small>
                            </div>
                        </a>
                    <?php endforeach; ?>
                </div>
            </div>

            <div class="chat-window">
                <?php if ($activeUser): ?>
                    <div class="chat-header">
                        <h2><?= htmlspecialchars($activeUser['first_name'] . ' ' . $activeUser['last_name']) ?></h2>
                    </div>
                    
                    <div class="chat-messages" id="chatContainer">
                        <?php foreach($messages as $msg): ?>
                            <div class="message <?= ($msg['sender_type'] == 'admin') ? 'sent' : 'received' ?>">
                                
                                <?php if(isset($msg['message_text']) && trim($msg['message_text']) !== ''): ?>
                                    <p><?= htmlspecialchars($msg['message_text']) ?></p>
                                <?php endif; ?>
                                
                                <?php if(!empty($msg['image_path'])): ?>
                                    <img src="../../../public/uploads/messages/<?= htmlspecialchars($msg['image_path']) ?>" alt="Attached Image">
                                <?php endif; ?>
                                <small style="display: block; margin-top: 5px; font-size: 0.7rem; opacity: 0.7;">
                                    <?= date('M d, h:i A', strtotime($msg['sent_at'])) ?>
                                </small>
                            </div>
                        <?php endforeach; ?>
                    </div>

                    <div class="chat-input" style="flex-direction: column; align-items: flex-start;">
                        
                        <div id="imagePreviewContainer" style="display: none; position: relative; margin-bottom: 10px; padding: 5px; background: #f9f9f9; border-radius: 8px; border: 1px solid #ddd; width: fit-content;">
                            <img id="imagePreview" src="" alt="Preview" style="max-height: 80px; border-radius: 5px; display: block;">
                            <button type="button" id="removeImageBtn" style="position: absolute; top: -8px; right: -8px; background: var(--color-danger, red); color: white; border: none; border-radius: 50%; width: 22px; height: 22px; cursor: pointer; font-size: 14px; font-weight: bold; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 5px rgba(0,0,0,0.2);">&#10005;</button>
                        </div>

                        <form action="messages.php" method="POST" enctype="multipart/form-data" style="display: flex; width: 100%; gap: 1rem; align-items: center;">
                            <input type="hidden" name="receiver_id" value="<?= $activeUserId ?>">
                            
                            <label for="chat_image_upload" class="file-upload-wrapper" title="Attach JPEG">
                                <span class="material-symbols-sharp text-muted" style="font-size: 2rem;">image</span>
                                <input type="file" id="chat_image_upload" name="chat_image" accept=".jpg, .jpeg">
                            </label>
                            
                            <input type="text" name="message_text" placeholder="Type a message..." autocomplete="off">
                            <button type="submit" name="send_message" class="btn-submit" style="width: auto; padding: 0.8rem 1.5rem;">Send</button>
                        </form>
                    </div>

                <?php else: ?>
                    <div style="display: flex; height: 100%; align-items: center; justify-content: center;" class="text-muted">
                        Select a user to start messaging.
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </main>
</div>

<script src="../../../public/js/script.js"></script>
<script>
    // 1. Auto-scroll to the bottom of the chat
    const chatContainer = document.getElementById('chatContainer');
    if (chatContainer) chatContainer.scrollTop = chatContainer.scrollHeight;

    // 2. Image Preview Logic
    const fileInput = document.getElementById('chat_image_upload');
    const previewContainer = document.getElementById('imagePreviewContainer');
    const previewImage = document.getElementById('imagePreview');
    const removeBtn = document.getElementById('removeImageBtn');

    // Make sure elements exist before adding listeners (prevents errors if no user is selected)
    if (fileInput && previewContainer && previewImage && removeBtn) {
        
        fileInput.addEventListener('change', function() {
            const file = this.files[0];
            
            if (file) {
                if (file.type.match('image.*')) {
                    const reader = new FileReader();
                    
                    reader.onload = function(e) {
                        previewImage.src = e.target.result;
                        previewContainer.style.display = 'block';
                    }
                    
                    reader.readAsDataURL(file);
                } else {
                    alert("Please select a valid image file.");
                    this.value = ''; 
                }
            }
        });

        removeBtn.addEventListener('click', function() {
            fileInput.value = ''; 
            previewContainer.style.display = 'none'; 
            previewImage.src = ''; 
        });
    }
</script>
</body>
</html>