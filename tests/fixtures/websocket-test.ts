// WebSocket server + client test
const server = Bun.serve({
    port: 0,
    fetch(req, server) {
        if (server.upgrade(req)) return;
        return new Response("not-ws");
    },
    websocket: {
        open(ws) { ws.send("ws-hello"); },
        message(ws, msg) { ws.send(`echo:${msg}`); },
        close() {},
    },
});

const ws = new WebSocket(`ws://localhost:${server.port}/`);

const result = await new Promise<string>((resolve) => {
    const timer = setTimeout(() => resolve("timeout"), 5000);
    ws.onmessage = (ev) => {
        clearTimeout(timer);
        resolve(String(ev.data));
    };
    ws.onerror = () => { clearTimeout(timer); resolve("error"); };
});

ws.close();
server.stop();
console.log(`websocket:${result === "ws-hello" ? "ok" : "fail:" + result}`);
