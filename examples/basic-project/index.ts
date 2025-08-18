#!/usr/bin/env bun
import chalk from "chalk";

console.log(chalk.blue("🥟 Hello from Bun on Termux!"));
console.log(chalk.green("✅ TypeScript support working"));
console.log(chalk.yellow("⚡ Fast JavaScript runtime"));

// Test Bun APIs
console.log(chalk.cyan(`📦 Bun version: ${Bun.version}`));
console.log(chalk.magenta(`🏠 Platform: ${process.platform}-${process.arch}`));

// Test file operations
const file = Bun.file("package.json");
const text = await file.text();
const packageInfo = JSON.parse(text);
console.log(chalk.green(`📋 Project: ${packageInfo.name} v${packageInfo.version}`));

// Test performance
const start = performance.now();
await new Promise(resolve => setTimeout(resolve, 10));
const end = performance.now();
console.log(chalk.blue(`⏱️  Timing precision: ${(end - start).toFixed(2)}ms`));

export default function main() {
  return "Bun on Termux is working! 🚀";
}