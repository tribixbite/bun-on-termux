// Test various Bun APIs
import { file, write, hash } from "bun";
import { tmpdir } from "os";
import { join } from "path";

const results: string[] = [];

// Bun.version
results.push(`version:${Bun.version}`);

// Bun.file + Bun.write
const tmpFile = join(tmpdir(), `bun-api-test-${Date.now()}.txt`);
await write(tmpFile, "test-content-42");
const content = await file(tmpFile).text();
results.push(`file-rw:${content === "test-content-42" ? "ok" : "fail"}`);

// Bun.hash
const h = hash("hello");
results.push(`hash:${typeof h === "number" ? "ok" : "fail"}`);

// Bun.sleepSync
const t0 = performance.now();
Bun.sleepSync(50);
const elapsed = performance.now() - t0;
results.push(`sleepSync:${elapsed >= 40 ? "ok" : "fail"}`);

// Bun.Transpiler
const transpiler = new Bun.Transpiler({ loader: "tsx" });
const code = transpiler.transformSync("const x: number = 1;");
results.push(`transpiler:${code.includes("const x") ? "ok" : "fail"}`);

// Bun.Glob
const glob = new Bun.Glob("*.ts");
results.push(`glob:${glob ? "ok" : "fail"}`);

// Clean up
const { unlinkSync } = require("fs");
try { unlinkSync(tmpFile); } catch {}

console.log(results.join(","));
