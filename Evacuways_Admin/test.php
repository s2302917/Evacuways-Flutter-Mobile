<?php
$target = __DIR__ . "/config/database.php";
if (file_exists($target)) {
    echo "✅ File found at: " . $target;
} else {
    echo "❌ File NOT found. Looking for: " . $target . "<br>";
    echo "Listing folders here:<br>";
    print_r(scandir(__DIR__));
}
?>