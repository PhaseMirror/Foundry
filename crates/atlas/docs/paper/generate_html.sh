#!/bin/bash

cat << 'EOF' > public/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UOR Atlas Whitepaper</title>
    <meta name="description" content="A Parametric, BDD-Driven, V&V-Gated Realization on Holospaces">
    <style>
        :root {
            --bg-color: #ffffff;
            --text-color: #222222;
            --link-color: #0366d6;
            --border-color: #eaecef;
        }
        
        body {
            margin: 0;
            padding: 0;
            font-family: 'Times New Roman', Times, serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            line-height: 1.6;
        }

        .container {
            max-width: 900px;
            margin: 40px auto;
            padding: 0 20px;
        }

        header {
            border-bottom: 2px solid var(--border-color);
            padding-bottom: 20px;
            margin-bottom: 30px;
        }

        h1 {
            font-size: 2.2em;
            margin-bottom: 10px;
            font-weight: normal;
        }

        .authors {
            font-size: 1.2em;
            font-style: italic;
            color: #555;
            margin-bottom: 5px;
        }
        
        .affiliation {
            font-size: 1em;
            color: #777;
        }

        .affiliation a {
            color: var(--link-color);
            text-decoration: none;
        }

        .affiliation a:hover {
            text-decoration: underline;
        }

        .abstract {
            background-color: #f6f8fa;
            border: 1px solid var(--border-color);
            padding: 20px;
            margin-bottom: 30px;
        }

        .abstract h2 {
            margin-top: 0;
            font-size: 1.2em;
        }

        .actions {
            margin: 30px 0;
            text-align: center;
        }

        .download-btn {
            display: inline-block;
            background-color: var(--link-color);
            color: #ffffff;
            text-decoration: none;
            padding: 12px 24px;
            font-family: Arial, sans-serif;
            font-weight: bold;
            border-radius: 4px;
            font-size: 1.1em;
        }
        
        .download-btn:hover {
            background-color: #0056b3;
        }

        .pdf-viewer {
            width: 100%;
            height: 800px;
            border: 1px solid var(--border-color);
        }
        
        footer {
            margin-top: 40px;
            padding-top: 20px;
            border-top: 1px solid var(--border-color);
            text-align: center;
        }
        
        footer img {
            width: 50px;
            height: auto;
            margin-bottom: 10px;
        }
        
        footer p {
            margin: 0;
            color: #777;
            font-size: 0.9em;
            font-family: Arial, sans-serif;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>The UOR Atlas as a Universal Topological Quantum Computer: A Formal Categorical Realization on Holospaces</h1>
            <div class="authors">The UOR Foundation</div>
            <div class="affiliation"><a href="https://uor.foundation">https://uor.foundation</a></div>
        </header>

        <div class="abstract">
            <h2>Abstract</h2>
            <p>
                This whitepaper formally details the realization of the Universal Topological Quantum Computer (UTQC) structured by the UOR Atlas. By leveraging the content-addressed <i>holospaces</i> substrate, the framework manifests topological-quantum modular tensor categories (MTC) computationally. We detail the resolution of three foundational mathematical obstructions&mdash;signed fusion constants, dimensionality mismatch, and indefinite spectral metrics&mdash;via structural absolute quotients, &#x2124;<sub>q</sub>-equivariant gauging, and pseudo-unitary metric relaxations. Furthermore, we report on the empirical demonstration of topological advantage via UOR cache-collapse, where framing algorithmic evaluations as topological decision problems over invariant k-forms subverts the #P-hard tensor contraction boundary, yielding massive compute and memory deduplication. All claims are guaranteed by rigorous computational proofs.
            </p>
        </div>

        <div class="actions">
            <a href="UOR_Atlas_Whitepaper.pdf" class="download-btn">Download PDF Whitepaper</a>
            <a href="https://github.com/afflom/UOR-Atlas-UTQC" class="download-btn" style="background-color: #24292e; margin-left: 10px;">View GitHub Repository</a>
        </div>

        <iframe src="UOR_Atlas_Whitepaper.pdf" class="pdf-viewer" title="UOR Atlas Whitepaper PDF"></iframe>
        
        <footer>
            <a href="https://uor.foundation">
                <img src="https://uor.foundation/assets/uor-icon-new-CQuNVmtH.png" alt="The UOR Foundation Logo">
            </a>
            <p>&copy; 2026 The UOR Foundation</p>
        </footer>
    </div>
</body>
</html>
EOF
