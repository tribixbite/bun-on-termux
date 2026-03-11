// Environment variable tests
const checks: string[] = [];

// Core env vars must exist
checks.push(`HOME:${process.env.HOME ? "ok" : "missing"}`);
checks.push(`PATH:${process.env.PATH ? "ok" : "missing"}`);
checks.push(`TERM:${process.env.TERM || "unset"}`);
checks.push(`SHELL:${process.env.SHELL ? "ok" : "missing"}`);

// Total env var count (should be > 10 with preload working)
const envCount = Object.keys(process.env).length;
checks.push(`env-count:${envCount}`);
checks.push(`env-sufficient:${envCount > 10 ? "ok" : "fail"}`);

console.log(checks.join(","));
