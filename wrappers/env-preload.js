// Termux glibc-runner env fix: populates process.env from /proc/self/environ
// When bun runs via glibc's ld.so, the C environ pointer is NULL but the
// kernel-level environment in /proc/self/environ is intact. This preload
// reads it and restores process.env so scripts see all environment variables.
const fs = require("fs");
try {
    if (Object.keys(process.env).length === 0) {
        const data = fs.readFileSync("/proc/self/environ", "utf8");
        for (const entry of data.split("\0")) {
            if (!entry) continue;
            const idx = entry.indexOf("=");
            if (idx > 0) {
                process.env[entry.substring(0, idx)] = entry.substring(idx + 1);
            }
        }
    }
} catch {
    // Silently fail if /proc/self/environ is not readable
}
