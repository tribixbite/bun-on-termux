// Stress / edge case tests
const results: string[] = [];

// Large array allocation (~80MB)
try {
    const arr = new Array(10_000_000).fill("x");
    results.push(`large-array:${arr.length === 10_000_000 ? "ok" : "fail"}`);
} catch (e: any) {
    results.push(`large-array:error:${e.message}`);
}

// Error handling: thrown error sets exit code
// (tested externally — this file just validates allocation)

// Deep string concatenation
try {
    let s = "";
    for (let i = 0; i < 100_000; i++) s += "a";
    results.push(`string-concat:${s.length === 100_000 ? "ok" : "fail"}`);
} catch (e: any) {
    results.push(`string-concat:error:${e.message}`);
}

// JSON parse large object
try {
    const obj: Record<string, number> = {};
    for (let i = 0; i < 10_000; i++) obj[`key${i}`] = i;
    const json = JSON.stringify(obj);
    const parsed = JSON.parse(json);
    results.push(`json-large:${Object.keys(parsed).length === 10_000 ? "ok" : "fail"}`);
} catch (e: any) {
    results.push(`json-large:error:${e.message}`);
}

console.log(results.join(","));
