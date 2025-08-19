#!/usr/bin/env bun
// Build script demonstration for Bun on Termux

import { $ } from "bun";

console.log("🏗️ Building Bun project on Termux...");

// Create output directory
console.log("📁 Creating output directory...");
await $`mkdir -p dist`;

// Bundle the main file
console.log("📦 Bundling TypeScript...");
const result = await Bun.build({
  entrypoints: ["./index.ts"],
  outdir: "./dist",
  target: "bun",
  sourcemap: "external",
  minify: false, // Keep readable for mobile debugging
});

if (result.success) {
  console.log("✅ Build successful!");
  console.log(`📦 Generated ${result.outputs.length} files:`);
  for (const output of result.outputs) {
    console.log(`   - ${output.path}`);
  }
} else {
  console.error("❌ Build failed!");
  for (const error of result.logs) {
    console.error(error);
  }
  process.exit(1);
}

// Create executable script
console.log("🔧 Creating executable script...");
const executableScript = `#!/data/data/com.termux/files/usr/bin/bash
# Generated executable for Bun on Termux
exec bun "${process.cwd()}/dist/index.js" "$@"
`;

await Bun.write("dist/bun-termux-example", executableScript);
await $`chmod +x dist/bun-termux-example`;

console.log("🎉 Build complete!");
console.log("📋 Run with: ./dist/bun-termux-example");
console.log("📋 Or directly: bun dist/index.js");