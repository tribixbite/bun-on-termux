// Low-level behavior tests (adapted from refbun/loader2 test patterns)
import { readlinkSync, readdirSync, existsSync, statSync } from "fs";
import { cpus, platform, arch } from "os";

const results: string[] = [];

// /proc/self/exe readlink
try {
    const exe = readlinkSync("/proc/self/exe");
    results.push(`proc-self-exe:${exe}`);
} catch (e: any) {
    results.push(`proc-self-exe:error:${e.code || e.message}`);
}

// os.cpus()
try {
    const c = cpus();
    results.push(`os-cpus:${c.length > 0 ? c.length + "-cores" : "empty"}`);
} catch (e: any) {
    results.push(`os-cpus:error:${e.message}`);
}

// process.platform / process.arch
results.push(`platform:${process.platform}`);
results.push(`arch:${process.arch}`);

// fs.readdirSync('/')
try {
    const entries = readdirSync("/");
    results.push(`readdir-root:${entries.length}-entries`);
} catch (e: any) {
    results.push(`readdir-root:error:${e.code || e.message}`);
}

// fs.existsSync('/data')
results.push(`exists-data:${existsSync("/data")}`);

// fs.statSync('/')
try {
    const st = statSync("/");
    results.push(`stat-root:${st.isDirectory() ? "ok" : "not-dir"}`);
} catch (e: any) {
    results.push(`stat-root:error:${e.code || e.message}`);
}

// process.cwd()
try {
    const cwd = process.cwd();
    results.push(`cwd:${cwd.length > 0 ? "ok" : "empty"}`);
} catch (e: any) {
    results.push(`cwd:error:${e.message}`);
}

console.log(results.join(","));
