// Simple HTTP server as cui-server fallback for Termux
import { serve } from "bun";

const port = process.env.PORT || 3000;
const host = process.env.HOST || "0.0.0.0";

const server = serve({
  port: parseInt(port.toString()),
  hostname: host,
  
  fetch(req) {
    const url = new URL(req.url);
    
    if (url.pathname === "/") {
      return new Response(`
<!DOCTYPE html>
<html>
<head>
    <title>Bun on Termux - Test Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .status { color: green; font-weight: bold; }
        .info { background: #f0f0f0; padding: 10px; margin: 10px 0; }
    </style>
</head>
<body>
    <h1>🚀 Bun on Termux Test Server</h1>
    <p class="status">✅ Server is running successfully!</p>
    
    <div class="info">
        <h3>Server Information:</h3>
        <ul>
            <li><strong>Host:</strong> ${host}</li>
            <li><strong>Port:</strong> ${port}</li>
            <li><strong>Bun Version:</strong> ${Bun.version}</li>
            <li><strong>Environment:</strong> Termux Android</li>
        </ul>
    </div>
    
    <div class="info">
        <h3>Available Endpoints:</h3>
        <ul>
            <li><a href="/">/</a> - This page</li>
            <li><a href="/api/status">/api/status</a> - JSON status</li>
            <li><a href="/api/info">/api/info</a> - System information</li>
        </ul>
    </div>
    
    <p><em>This server demonstrates that <code>bunx</code> and Bun are working correctly in Termux.</em></p>
</body>
</html>
      `, {
        headers: { "Content-Type": "text/html" }
      });
    }
    
    if (url.pathname === "/api/status") {
      return Response.json({
        status: "ok",
        server: "bun-on-termux",
        version: Bun.version,
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
      });
    }
    
    if (url.pathname === "/api/info") {
      return Response.json({
        bun: {
          version: Bun.version,
          platform: process.platform,
          arch: process.arch
        },
        process: {
          pid: process.pid,
          uptime: process.uptime(),
          memory: process.memoryUsage()
        },
        server: {
          host,
          port,
          url: `http://${host}:${port}`
        }
      });
    }
    
    return new Response("Not Found", { status: 404 });
  },
});

console.log(`🚀 Server running at http://${host}:${port}`);
console.log(`📱 On Termux, access via: http://localhost:${port}`);
console.log(`🌐 From other devices: http://[your-ip]:${port}`);
