#!/usr/bin/env bun
// Fetch and HTTP client demonstration for Bun on Termux

import chalk from "chalk";

console.log(chalk.blue("🌐 Fetch & HTTP demo on Termux...\n"));

// Basic fetch example
console.log(chalk.green("📡 Basic Fetch:"));

try {
  console.log(chalk.gray("Fetching httpbin.org/json..."));
  const response = await fetch("https://httpbin.org/json");
  
  if (response.ok) {
    const data = await response.json();
    console.log(chalk.cyan("Status:"), response.status);
    console.log(chalk.cyan("Headers:"), response.headers.get("content-type"));
    console.log(chalk.cyan("Data:"), JSON.stringify(data, null, 2));
  } else {
    console.log(chalk.red("❌ Request failed:"), response.status);
  }
} catch (error) {
  console.log(chalk.red("❌ Network error:"), error.message);
}

// POST request with JSON
console.log(chalk.green("\n📤 POST Request:"));

try {
  console.log(chalk.gray("Posting to httpbin.org/post..."));
  const postData = {
    message: "Hello from Bun on Termux!",
    timestamp: new Date().toISOString(),
    platform: "android",
    runtime: "bun"
  };

  const postResponse = await fetch("https://httpbin.org/post", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "User-Agent": "Bun-Termux/1.0"
    },
    body: JSON.stringify(postData)
  });

  if (postResponse.ok) {
    const result = await postResponse.json();
    console.log(chalk.cyan("Posted data:"), JSON.stringify(result.json, null, 2));
    console.log(chalk.cyan("Headers sent:"), JSON.stringify(result.headers, null, 2));
  }
} catch (error) {
  console.log(chalk.red("❌ POST error:"), error.message);
}

// Multiple concurrent requests
console.log(chalk.green("\n🚀 Concurrent Requests:"));

const urls = [
  "https://httpbin.org/delay/1",
  "https://httpbin.org/delay/2", 
  "https://httpbin.org/delay/1",
  "https://httpbin.org/uuid"
];

console.log(chalk.gray(`Making ${urls.length} concurrent requests...`));

const start = performance.now();

try {
  const promises = urls.map(async (url, index) => {
    const response = await fetch(url);
    return {
      index,
      url,
      status: response.status,
      size: parseInt(response.headers.get("content-length") || "0")
    };
  });

  const results = await Promise.all(promises);
  const duration = performance.now() - start;

  console.log(chalk.cyan("Results:"));
  results.forEach(result => {
    console.log(`  ${result.index + 1}. ${result.url} → ${result.status} (${result.size} bytes)`);
  });
  console.log(chalk.cyan("Duration:"), `${Math.round(duration)}ms`);

} catch (error) {
  console.log(chalk.red("❌ Concurrent requests error:"), error.message);
}

// File download simulation
console.log(chalk.green("\n⬇️ File Download Simulation:"));

try {
  console.log(chalk.gray("Downloading image..."));
  const imageUrl = "https://httpbin.org/bytes/1024"; // 1KB of random data
  
  const imageResponse = await fetch(imageUrl);
  if (imageResponse.ok) {
    const arrayBuffer = await imageResponse.arrayBuffer();
    const bytes = new Uint8Array(arrayBuffer);
    
    console.log(chalk.cyan("Downloaded:"), `${bytes.length} bytes`);
    console.log(chalk.cyan("First 16 bytes:"), Array.from(bytes.slice(0, 16)).map(b => b.toString(16).padStart(2, '0')).join(' '));
    
    // Save to file
    await Bun.write("/tmp/downloaded-data.bin", bytes);
    console.log(chalk.cyan("Saved to:"), "/tmp/downloaded-data.bin");
  }
} catch (error) {
  console.log(chalk.red("❌ Download error:"), error.message);
}

// Custom headers and authentication simulation
console.log(chalk.green("\n🔐 Custom Headers & Auth:"));

try {
  console.log(chalk.gray("Testing custom headers..."));
  const authResponse = await fetch("https://httpbin.org/headers", {
    headers: {
      "Authorization": "Bearer fake-token-123",
      "X-Custom-Header": "Bun-Termux",
      "Accept": "application/json",
      "User-Agent": "Bun/1.0 (Termux; Android)"
    }
  });

  if (authResponse.ok) {
    const headerData = await authResponse.json();
    console.log(chalk.cyan("Received headers:"));
    Object.entries(headerData.headers).forEach(([key, value]) => {
      console.log(`  ${key}: ${value}`);
    });
  }
} catch (error) {
  console.log(chalk.red("❌ Headers test error:"), error.message);
}

// Performance benchmark
console.log(chalk.green("\n⚡ Performance Benchmark:"));

async function benchmarkRequests(count: number) {
  console.log(chalk.gray(`Making ${count} sequential requests...`));
  
  const start = performance.now();
  let successful = 0;
  let failed = 0;

  for (let i = 0; i < count; i++) {
    try {
      const response = await fetch("https://httpbin.org/get");
      if (response.ok) {
        successful++;
        await response.text(); // Consume response
      } else {
        failed++;
      }
    } catch {
      failed++;
    }
  }

  const duration = performance.now() - start;
  const requestsPerSecond = Math.round(count / (duration / 1000));

  return {
    count,
    successful,
    failed,
    duration: Math.round(duration),
    requestsPerSecond
  };
}

try {
  const benchmark = await benchmarkRequests(10);
  console.log(chalk.cyan("Benchmark results:"));
  console.log(`  Total requests: ${benchmark.count}`);
  console.log(`  Successful: ${benchmark.successful}`);
  console.log(`  Failed: ${benchmark.failed}`);
  console.log(`  Duration: ${benchmark.duration}ms`);
  console.log(`  Rate: ${benchmark.requestsPerSecond} req/sec`);
} catch (error) {
  console.log(chalk.red("❌ Benchmark error:"), error.message);
}

// WebSocket simulation (if available)
console.log(chalk.green("\n🔌 WebSocket Test:"));

try {
  // Note: WebSocket might not work in all Termux environments
  console.log(chalk.yellow("⚠️ WebSocket support varies in Termux environments"));
  console.log(chalk.gray("This would require a WebSocket server for full testing"));
  
  // Demonstrate WebSocket creation (won't connect without server)
  const wsUrl = "wss://echo.websocket.org";
  console.log(chalk.cyan("WebSocket URL:"), wsUrl);
  console.log(chalk.cyan("Note:"), "WebSocket connections require stable network and may not work in all Termux setups");
  
} catch (error) {
  console.log(chalk.red("❌ WebSocket error:"), error.message);
}

console.log(chalk.green("\n✅ Fetch & HTTP demo completed!"));