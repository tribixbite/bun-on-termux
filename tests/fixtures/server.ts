// Bun.serve() test - starts server, fetches, prints response, shuts down
const server = Bun.serve({
    port: 0, // random available port
    fetch(req) {
        return new Response("bun-serve-ok");
    },
});

const res = await fetch(`http://localhost:${server.port}/`);
const text = await res.text();
console.log(`server-test:${text}`);
server.stop();
