// Bun $ shell API test
const results: string[] = [];

try {
    const output = await Bun.$`echo shell-api-works`.text();
    results.push(`shell:${output.trim() === "shell-api-works" ? "ok" : "fail:" + output.trim()}`);
} catch (e: any) {
    results.push(`shell:error:${e.message}`);
}

try {
    const output = await Bun.$`echo $HOME`.text();
    results.push(`shell-env:${output.trim().length > 0 ? "ok" : "empty"}`);
} catch (e: any) {
    results.push(`shell-env:error:${e.message}`);
}

console.log(results.join(","));
