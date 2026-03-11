// Worker thread test
import { join } from "path";

// Create worker script inline via Blob
const workerCode = `
    self.onmessage = (e) => {
        self.postMessage("worker-reply:" + e.data);
    };
`;
const blob = new Blob([workerCode], { type: "application/javascript" });
const url = URL.createObjectURL(blob);

const result = await new Promise<string>((resolve) => {
    const timer = setTimeout(() => resolve("timeout"), 5000);
    try {
        const worker = new Worker(url);
        worker.onmessage = (e) => {
            clearTimeout(timer);
            worker.terminate();
            resolve(String(e.data));
        };
        worker.onerror = (e) => {
            clearTimeout(timer);
            resolve("error:" + e.message);
        };
        worker.postMessage("test");
    } catch (e: any) {
        clearTimeout(timer);
        resolve("error:" + e.message);
    }
});

URL.revokeObjectURL(url);
console.log(`worker:${result.startsWith("worker-reply:") ? "ok" : "fail:" + result}`);
