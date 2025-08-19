#!/usr/bin/env bun

console.log("🥟 Hello from Bun on Termux!");
console.log("✅ TypeScript support working");
console.log("⚡ Fast JavaScript runtime");

// Test Bun APIs
console.log(`📦 Bun version: ${Bun.version}`);
console.log(`🏠 Platform: ${process.platform}-${process.arch}`);

// Test file operations
const file = Bun.file("package.json");
const text = await file.text();
const packageInfo = JSON.parse(text);
console.log(`📋 Project: ${packageInfo.name} v${packageInfo.version}`);

// Test performance
const start = performance.now();
await new Promise(resolve => setTimeout(resolve, 10));
const end = performance.now();
console.log(`⏱️  Timing precision: ${(end - start).toFixed(2)}ms`);

export default function main() {
  return "Bun on Termux is working! 🚀";
}