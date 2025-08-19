#!/usr/bin/env bun
// Performance benchmarks for Bun on Termux

console.log("🚀 Running Bun benchmarks on Termux...\n");

interface BenchmarkResult {
  name: string;
  duration: number;
  operations: number;
  opsPerSecond: number;
}

function benchmark(name: string, fn: () => void, iterations = 100000): BenchmarkResult {
  console.log(`Running ${name}...`);
  
  const start = performance.now();
  for (let i = 0; i < iterations; i++) {
    fn();
  }
  const duration = performance.now() - start;
  
  const opsPerSecond = Math.round(iterations / (duration / 1000));
  
  return {
    name,
    duration: Math.round(duration * 100) / 100,
    operations: iterations,
    opsPerSecond
  };
}

// CPU-intensive benchmarks
const results: BenchmarkResult[] = [];

results.push(benchmark("Math operations", () => {
  Math.sqrt(Math.random() * 1000);
}));

results.push(benchmark("String operations", () => {
  "hello world".repeat(10).toUpperCase().slice(0, 50);
}));

results.push(benchmark("Array operations", () => {
  const arr = [1, 2, 3, 4, 5];
  arr.map(x => x * 2).filter(x => x > 5).reduce((a, b) => a + b, 0);
}));

results.push(benchmark("Object operations", () => {
  const obj = { a: 1, b: 2, c: 3 };
  JSON.stringify(JSON.parse(JSON.stringify(obj)));
}));

// File system benchmark
async function fileBenchmark() {
  console.log("Running file operations...");
  
  const start = performance.now();
  const iterations = 100;
  
  for (let i = 0; i < iterations; i++) {
    const file = Bun.file(`./test-${i}.txt`);
    await Bun.write(file, `test data ${i}`);
    await file.text();
    // Clean up
    try {
      await Bun.write(file, "");
    } catch {
      // Ignore cleanup errors
    }
  }
  
  const duration = performance.now() - start;
  const opsPerSecond = Math.round(iterations / (duration / 1000));
  
  results.push({
    name: "File I/O operations",
    duration: Math.round(duration * 100) / 100,
    operations: iterations,
    opsPerSecond
  });
}

await fileBenchmark();

// Memory usage
const memUsage = process.memoryUsage();

console.log("\n📊 Benchmark Results:");
console.log("=".repeat(60));

for (const result of results) {
  console.log(`${result.name}:`);
  console.log(`  Duration: ${result.duration}ms`);
  console.log(`  Operations: ${result.operations.toLocaleString()}`);
  console.log(`  Ops/sec: ${result.opsPerSecond.toLocaleString()}`);
  console.log();
}

console.log("💾 Memory Usage:");
console.log(`  Heap Used: ${Math.round(memUsage.heapUsed / 1024 / 1024)}MB`);
console.log(`  Heap Total: ${Math.round(memUsage.heapTotal / 1024 / 1024)}MB`);
console.log(`  External: ${Math.round(memUsage.external / 1024 / 1024)}MB`);
console.log(`  RSS: ${Math.round(memUsage.rss / 1024 / 1024)}MB`);

console.log("\n✅ Benchmarks completed!");