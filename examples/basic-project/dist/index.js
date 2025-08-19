#!/usr/bin/env bun
// @bun

// index.ts
console.log("\uD83E\uDD5F Hello from Bun on Termux!");
console.log("\u2705 TypeScript support working");
console.log("\u26A1 Fast JavaScript runtime");
console.log(`\uD83D\uDCE6 Bun version: ${Bun.version}`);
console.log(`\uD83C\uDFE0 Platform: ${process.platform}-${process.arch}`);
var file = Bun.file("package.json");
var text = await file.text();
var packageInfo = JSON.parse(text);
console.log(`\uD83D\uDCCB Project: ${packageInfo.name} v${packageInfo.version}`);
var start = performance.now();
await new Promise((resolve) => setTimeout(resolve, 10));
var end = performance.now();
console.log(`\u23F1\uFE0F  Timing precision: ${(end - start).toFixed(2)}ms`);
function main() {
  return "Bun on Termux is working! \uD83D\uDE80";
}
export {
  main as default
};

//# debugId=7E0284AA36D404C664756E2164756E21
