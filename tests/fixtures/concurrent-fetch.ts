// Concurrent HTTP fetch test
const s = Bun.serve({ port: 0, fetch: () => new Response("ok") });
const results = await Promise.all(
    [1, 2, 3].map(() => fetch(`http://localhost:${s.port}`).then(r => r.text()))
);
s.stop();
console.log("concurrent:" + (results.every(x => x === "ok") ? "ok" : "fail"));
