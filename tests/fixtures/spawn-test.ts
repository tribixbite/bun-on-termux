// Test Bun.spawn / Bun.spawnSync behavior
const results: string[] = [];

// Bun.spawnSync basic
try {
    const proc = Bun.spawnSync(["echo", "spawn-ok"]);
    const out = proc.stdout.toString().trim();
    results.push(`spawnSync:${out === "spawn-ok" ? "ok" : "fail:" + out}`);
} catch (e: any) {
    results.push(`spawnSync:error:${e.message}`);
}

// Child inherits env
try {
    const proc = Bun.spawnSync(["env"]);
    const out = proc.stdout.toString();
    const hasHome = out.includes("HOME=");
    results.push(`child-env:${hasHome ? "ok" : "no-HOME"}`);
} catch (e: any) {
    results.push(`child-env:error:${e.message}`);
}

// Nested bun invocation
try {
    const proc = Bun.spawnSync(["bun", "--version"]);
    const out = proc.stdout.toString().trim();
    results.push(`nested-bun:${out.match(/^\d+\.\d+/) ? "ok:" + out : "fail:" + out}`);
} catch (e: any) {
    results.push(`nested-bun:error:${e.message}`);
}

// $ shell API
try {
    const result = Bun.spawnSync(["echo", "shell-api-ok"]);
    results.push(`shell-spawn:${result.exitCode === 0 ? "ok" : "fail"}`);
} catch (e: any) {
    results.push(`shell-spawn:error:${e.message}`);
}

console.log(results.join(","));
