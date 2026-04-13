<?php
session_start();
if (isset($_SESSION['admin_id'])) {
    header("Location: app/views/dashboard/dashboard.php");
    exit();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login | EvacuWays Admin</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Sharp" />
    <style>
        :root {
            --bg: #f8fafc;
            --white: #ffffff;
            --primary: #fd626c; 
            --primary-hover: #e54d57;
            --text-main: #1e293b;
            --text-light: #64748b;
            --danger: #ef4444;
            --radius: 24px;
            --shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
        }

        body { 
            display: flex; 
            align-items: center; 
            justify-content: center; 
            min-height: 100vh; 
            background: var(--bg); 
            font-family: 'Poppins', sans-serif;
            margin: 0;
            padding: 20px;
        }

        .login-card { 
            background: var(--white); 
            padding: 3.5rem 2.5rem; 
            border-radius: var(--radius); 
            box-shadow: var(--shadow); 
            width: 100%; 
            max-width: 420px; 
            text-align: center; 
        }

        /* CENTERED LOGO */
        .brand-logo { 
            width: 100px; 
            height: auto;
            display: block; 
            margin: 0 auto 1.5rem; 
            filter: drop-shadow(0 4px 6px rgba(0,0,0,0.1));
        }

        .login-card h1 { 
            color: var(--text-main); 
            font-size: 1.8rem; 
            font-weight: 700;
            margin: 0 0 0.5rem 0; 
        }

        .subtitle { 
            color: var(--text-light); 
            font-size: 0.95rem;
            margin-bottom: 2.5rem; 
        }

        /* Error Message Styling */
        .error-msg { 
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            color: var(--danger); 
            background: #fef2f2; 
            padding: 0.8rem; 
            border-radius: 12px; 
            margin-bottom: 1.5rem; 
            font-size: 0.85rem; 
            border: 1px solid #fee2e2;
            font-weight: 500;
        }

        /* Input Styling */
        .input-group { 
            text-align: left; 
            margin-bottom: 1.25rem; 
        }

        .input-group label { 
            display: block;
            font-size: 0.85rem; 
            font-weight: 600; 
            color: var(--text-main); 
            margin-bottom: 0.5rem; 
            margin-left: 5px;
        }

        .input-wrapper {
            position: relative;
            display: flex;
            align-items: center;
        }

        .input-wrapper .material-symbols-sharp {
            position: absolute;
            left: 14px;
            color: var(--text-light);
            font-size: 1.3rem;
        }

        .input-wrapper input {
            width: 100%;
            padding: 0.9rem 1rem 0.9rem 45px; 
            border-radius: 14px;
            border: 1.5px solid #e2e8f0;
            background: #fdfdfd;
            font-family: inherit;
            font-size: 1rem;
            transition: all 0.2s ease;
            outline: none;
            box-sizing: border-box;
        }

        .input-wrapper input:focus { 
            border-color: var(--primary); 
            background: #fff;
            box-shadow: 0 0 0 4px rgba(253, 98, 108, 0.1);
        }

        /* Button Styling */
        .btn-submit {
            background: var(--primary);
            color: white;
            border: none;
            width: 100%;
            padding: 1.1rem;
            border-radius: 14px;
            font-weight: 600;
            font-size: 1rem;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-top: 1.5rem;
            box-shadow: 0 4px 12px rgba(253, 98, 108, 0.2);
        }

        .btn-submit:hover { 
            background: var(--primary-hover); 
            transform: translateY(-2px);
            box-shadow: 0 6px 15px rgba(253, 98, 108, 0.3);
        }

        .footer-text {
            margin-top: 2rem;
            font-size: 0.85rem;
            color: var(--text-light);
        }

        .footer-text a {
            color: var(--primary);
            text-decoration: none;
            font-weight: 600;
        }
    </style>
</head>
<body>

    <div class="login-card">
        <img src="public/images/logo.png" alt="EvacuWays" class="brand-logo">
        
        <h1>Admin Portal</h1>
        <p class="subtitle">Enter your credentials to manage response.</p>

        <?php if(isset($_GET['error'])): ?>
            <div class="error-msg">
                <span class="material-symbols-sharp">error</span>
                Invalid email or password.
            </div>
        <?php endif; ?>

        <form id="loginForm" action="app/auth/login_process.php" method="POST">
            <div class="input-group">
                <label>Email Address</label>
                <div class="input-wrapper">
                    <span class="material-symbols-sharp">alternate_email</span>
                    <input type="email" name="email" required placeholder="admin@evacuways.ph">
                </div>
            </div>

            <div class="input-group" style="margin-bottom: 0.5rem;">
                <label>Password</label>
                <div class="input-wrapper">
                    <span class="material-symbols-sharp">lock_person</span>
                    <input type="password" name="password" required placeholder="••••••••">
                </div>
            </div>

            <div style="text-align: right; margin-bottom: 1.5rem;">
                <a href="#" style="font-size: 0.8rem; color: var(--text-light); text-decoration: none;">Forgot Password?</a>
            </div>
            
            <input type="hidden" name="lat" id="lat">
            <input type="hidden" name="lng" id="lng">

            <button type="submit" class="btn-submit">Secure Login</button>
        </form>

        <p class="footer-text">
            System issue? <a href="about.php">Contact Technical Team</a>
        </p>
    </div>

    <script>
        // Location capture
        if ("geolocation" in navigator) {
            navigator.geolocation.getCurrentPosition(
                pos => {
                    document.getElementById('lat').value = pos.coords.latitude;
                    document.getElementById('lng').value = pos.coords.longitude;
                },
                err => { console.warn("Location permission denied."); }
            );
        }
    </script>
</body>
</html>