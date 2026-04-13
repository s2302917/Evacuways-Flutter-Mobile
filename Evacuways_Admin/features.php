<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Features | EvacuWays</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Sharp" />
    <style>
        :root {
            --primary: #fd626c;
            --bg: #f4f6f9;
            --card-bg: #ffffff;
            --text: #1f2937;
            --text-light: #6b7280;
            --shadow: 0 10px 30px rgba(0, 0, 0, 0.08);
            --radius: 16px;
            --radius-sm: 8px;
            --transition: 0.3s ease;
        }

        body { font-family: 'Poppins', sans-serif; background: var(--bg); color: var(--text); margin: 0; }
        
        /* Navigation */
        .main-nav {
            display: flex; justify-content: space-between; align-items: center;
            padding: 1.2rem 8%; background: var(--card-bg); box-shadow: var(--shadow);
            position: sticky; top: 0; z-index: 1000;
        }
        .main-nav .logo { display: flex; align-items: center; gap: 0.8rem; }
        .main-nav .logo img { width: 3.5rem; }
        .main-nav .logo h2 { font-size: 1.8rem; margin: 0; font-weight: 700; }

        .nav-links { display: flex; align-items: center; gap: 2rem; }
        .nav-links a { font-weight: 500; color: var(--text-light); text-decoration: none; transition: var(--transition); }
        .nav-links a:hover { color: var(--primary); }
        
        .btn-login-accent {
            background: var(--primary); color: white !important; padding: 0.7rem 1.8rem;
            border-radius: var(--radius-sm); font-weight: 600; box-shadow: 0 4px 14px rgba(253, 98, 108, 0.3);
        }

        /* Page Content */
        .page-header { text-align: center; padding: 6rem 8% 4rem; background: var(--card-bg); }
        .page-header h1 { font-size: 3rem; margin-bottom: 1rem; }
        .page-header h1 span { color: var(--primary); }

        .features-detailed {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2.5rem; padding: 4rem 8% 8rem;
        }

        .obj-card {
            background: var(--card-bg); padding: 3.5rem 2.5rem; border-radius: var(--radius);
            text-align: center; box-shadow: var(--shadow); transition: var(--transition);
        }
        .obj-card:hover { transform: translateY(-10px); }
        .obj-card span { font-size: 4rem; color: var(--primary); margin-bottom: 1.5rem; display: block; }
        .obj-card h3 { font-size: 1.4rem; margin-bottom: 1rem; color: var(--text); text-transform: none; }
        .obj-card p { color: var(--text-light); line-height: 1.7; font-size: 1rem; }

        @media (max-width: 768px) { .features-detailed { grid-template-columns: 1fr; } }
    </style>
</head>
<body>

    <nav class="main-nav">
        <div class="logo">
            <img src="public/images/logo.png" alt="Logo">
            <h2>EvacuWays</h2>
        </div>
        <div class="nav-links">
            <a href="homepage.php">Home</a>
            <a href="about.php">About</a>
            <a href="features.php" style="color: var(--primary);">Features</a>
            <a href="index.php" class="btn-login-accent">Login</a>
        </div>
    </nav>

    <header class="page-header">
        <h1>System <span>Objectives</span></h1>
        <p>Advanced tools designed for families, volunteers, and local authorities.</p>
    </header>

    <section class="features-detailed">
        <div class="obj-card">
            <span class="material-symbols-sharp">hub</span>
            <h3>Consolidate Alerts</h3>
            <p>Combining warnings from LGUs, social media, and radio into one feed to reduce confusion during emergencies.</p>
        </div>

        <div class="obj-card">
            <span class="material-symbols-sharp">offline_pin</span>
            <h3>Offline Resilience</h3>
            <p>Access preparation guidelines and emergency maps even when data networks fail during a storm.</p>
        </div>

        <div class="obj-card">
            <span class="material-symbols-sharp">accessible_forward</span>
            <h3>Vulnerability Support</h3>
            <p>Personalized checklists and voice alerts tailored for children, senior citizens, and PWDs.</p>
        </div>

        <div class="obj-card">
            <span class="material-symbols-sharp">groups</span>
            <h3>Community Coordination</h3>
            <p>Scalable reporting features that allow volunteers and support groups to coordinate transportation and supplies.</p>
        </div>
    </section>

</body>
</html>