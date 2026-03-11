// Test that child processes inherit environment
const proc = Bun.spawnSync(["env"]);
const out = proc.stdout.toString();
const hasPath = out.includes("PATH=");
console.log("child-path:" + (hasPath ? "ok" : "missing"));
