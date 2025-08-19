#!/usr/bin/env bun
// Advanced Bun server demonstration for Termux

import chalk from "chalk";

console.log(chalk.blue("🚀 Starting Bun server on Termux..."));

const server = Bun.serve({
  port: 3000,
  hostname: "localhost",
  
  async fetch(req) {
    const url = new URL(req.url);
    
    // Handle different routes
    switch (url.pathname) {
      case "/":
        return new Response(createHomePage(), {
          headers: { "Content-Type": "text/html" }
        });
        
      case "/api/system":
        return Response.json({
          bun_version: Bun.version,
          platform: process.platform,
          arch: process.arch,
          memory: {
            used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
            total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024)
          },
          uptime: Math.round(process.uptime()),
          termux: true
        });
        
      case "/api/files":
        try {
          const files = await Array.fromAsync(
            new Bun.Glob("*").scan(".")
          );
          return Response.json({ files });
        } catch (error) {
          return Response.json({ error: "Could not read directory" }, { status: 500 });
        }
        
      case "/api/benchmark":
        const start = performance.now();
        // Simple CPU benchmark
        let sum = 0;
        for (let i = 0; i < 1000000; i++) {
          sum += Math.sqrt(i);
        }
        const duration = performance.now() - start;
        
        return Response.json({
          benchmark: "sqrt_1M",
          duration_ms: Math.round(duration * 100) / 100,
          result: Math.round(sum)
        });
        
      default:
        return new Response("Not Found", { status: 404 });
    }
  },
  
  error(error) {
    console.error(chalk.red("❌ Server error:"), error);
    return new Response("Internal Server Error", { status: 500 });
  }
});

function createHomePage() {
  return `
<!DOCTYPE html>
<html>
<head>
    <title>Bun on Termux Demo</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: system-ui; margin: 2rem; background: #1a1a1a; color: #fff; }
        .container { max-width: 800px; margin: 0 auto; }
        .card { background: #2a2a2a; padding: 1.5rem; margin: 1rem 0; border-radius: 8px; }
        button { background: #0084ff; color: white; border: none; padding: 0.5rem 1rem; border-radius: 4px; cursor: pointer; margin: 0.25rem; }
        button:hover { background: #0066cc; }
        pre { background: #333; padding: 1rem; border-radius: 4px; overflow-x: auto; }
        .status { padding: 0.5rem; border-radius: 4px; margin: 0.5rem 0; }
        .success { background: #0d4f3c; color: #4ade80; }
        .info { background: #1e3a8a; color: #60a5fa; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🥟 Bun on Termux Demo Server</h1>
        
        <div class="card">
            <h2>System Information</h2>
            <div id="system-info">
                <button onclick="loadSystemInfo()">Load System Info</button>
            </div>
        </div>
        
        <div class="card">
            <h2>File System</h2>
            <div id="files-info">
                <button onclick="loadFiles()">List Files</button>
            </div>
        </div>
        
        <div class="card">
            <h2>Performance Benchmark</h2>
            <div id="benchmark-info">
                <button onclick="runBenchmark()">Run Benchmark</button>
            </div>
        </div>
        
        <div class="card">
            <h2>About</h2>
            <p>This server demonstrates Bun's capabilities on Termux Android:</p>
            <ul>
                <li>Native HTTP server with Bun.serve</li>
                <li>File system operations with Bun.Glob</li>
                <li>Performance monitoring</li>
                <li>JSON API endpoints</li>
                <li>Error handling</li>
            </ul>
        </div>
    </div>
    
    <script>
        async function loadSystemInfo() {
            const container = document.getElementById('system-info');
            container.innerHTML = '<div class="info">Loading...</div>';
            
            try {
                const response = await fetch('/api/system');
                const data = await response.json();
                container.innerHTML = \`
                    <div class="success">✅ System info loaded</div>
                    <pre>\${JSON.stringify(data, null, 2)}</pre>
                \`;
            } catch (error) {
                container.innerHTML = \`<div style="background: #dc2626; color: white; padding: 0.5rem; border-radius: 4px;">❌ Error: \${error.message}</div>\`;
            }
        }
        
        async function loadFiles() {
            const container = document.getElementById('files-info');
            container.innerHTML = '<div class="info">Loading...</div>';
            
            try {
                const response = await fetch('/api/files');
                const data = await response.json();
                container.innerHTML = \`
                    <div class="success">✅ Files loaded</div>
                    <pre>\${JSON.stringify(data, null, 2)}</pre>
                \`;
            } catch (error) {
                container.innerHTML = \`<div style="background: #dc2626; color: white; padding: 0.5rem; border-radius: 4px;">❌ Error: \${error.message}</div>\`;
            }
        }
        
        async function runBenchmark() {
            const container = document.getElementById('benchmark-info');
            container.innerHTML = '<div class="info">Running benchmark...</div>';
            
            try {
                const response = await fetch('/api/benchmark');
                const data = await response.json();
                container.innerHTML = \`
                    <div class="success">✅ Benchmark completed</div>
                    <pre>\${JSON.stringify(data, null, 2)}</pre>
                \`;
            } catch (error) {
                container.innerHTML = \`<div style="background: #dc2626; color: white; padding: 0.5rem; border-radius: 4px;">❌ Error: \${error.message}</div>\`;
            }
        }
    </script>
</body>
</html>`;
}

console.log(chalk.green(`✅ Server running on http://localhost:${server.port}`));
console.log(chalk.yellow("📱 Open in Termux browser or connect from PC on same network"));
console.log(chalk.gray("   Press Ctrl+C to stop"));

// Graceful shutdown
process.on("SIGINT", () => {
  console.log(chalk.blue("\n👋 Shutting down server..."));
  server.stop();
  process.exit(0);
});