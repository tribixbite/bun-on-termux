// Bun.password API test
const results: string[] = [];

try {
    const hashed = await Bun.password.hash("test-password");
    results.push(`hash:${hashed.length > 10 ? "ok" : "fail"}`);

    const valid = await Bun.password.verify("test-password", hashed);
    results.push(`verify:${valid ? "ok" : "fail"}`);

    const invalid = await Bun.password.verify("wrong-password", hashed);
    results.push(`reject:${!invalid ? "ok" : "fail"}`);
} catch (e: any) {
    results.push(`password:error:${e.message}`);
}

console.log(results.join(","));
