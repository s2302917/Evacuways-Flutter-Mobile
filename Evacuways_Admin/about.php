<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>About | EvacuWays</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Material+Symbols+Sharp" />
    <style>
        :root {
            --primary: #fd626c;
            --primary-variant: #e54d57;
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
        .main-nav .logo h2 { font-size: 1.8rem; margin: 0; font-weight: 700; color: var(--text); }
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
        .page-header p { color: var(--text-light); font-size: 1.1rem; }

        .content-container { padding: 4rem 8%; }
        .info-grid { display: grid; grid-template-columns: 2fr 1fr; gap: 4rem; align-items: start; }
        .info-text h2 { font-size: 2rem; margin-bottom: 1rem; color: var(--primary); }
        .info-text p { line-height: 1.8; color: var(--text-light); margin-bottom: 2rem; }

        .info-card-highlight {
            background: var(--primary); color: white; padding: 2.5rem; border-radius: var(--radius);
            box-shadow: 0 10px 20px rgba(253, 98, 108, 0.2);
        }
        .info-card-highlight h3 { color: white; text-transform: none; font-size: 1.5rem; margin-bottom: 1.5rem; }
        .info-card-highlight ul { list-style: none; padding: 0; }
        .info-card-highlight li { display: flex; align-items: center; gap: 1rem; margin-bottom: 1.2rem; }

        @media (max-width: 992px) { .info-grid { grid-template-columns: 1fr; } }
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
            <a href="about.php" style="color: var(--primary);">About</a>
            <a href="features.php">Features</a>
            <a href="index.php" class="btn-login-accent">Login</a>
        </div>
    </nav>

    <header class="page-header">
        <h1>About the <span>Project</span></h1>
        <p>Strengthening disaster resilience in Western Visayas through centralized coordination.</p>
    </header>

    <section class="content-container">
        <div class="info-grid">
            <div class="info-text">
                <h2>The Problem</h2>
                <p>In the Philippines, particularly in Western Visayas, typhoons and floods are frequent. Currently, evacuation info is spread across social media, radio, and word-of-mouth. This <strong>fragmented communication</strong> results in confusion, delayed evacuations, and increased risk for our community.</p>
                
                <h2>Our Mission</h2>
                <p>EvacuWays aims to centralize all evacuation-related information into a single, reliable platform. We help residents make timely decisions by providing verified updates, real-time notifications, and personalized tools.</p>
            </div>
            <div class="info-card-highlight">
                <h3>Target Regions</h3>
                <ul>
                    <li><span class="material-symbols-sharp">location_on</span> High-risk Barangays</li>
                    <li><span class="material-symbols-sharp">tsunami</span> Flood-prone Areas</li>
                    <li><span class="material-symbols-sharp">cyclone</span> Typhoon-prone Districts</li>
                </ul>
            </div>
        </div>
    </section>

</body>
</html>