import { test, expect } from "bun:test";

test("basic math", () => {
  expect(2 + 2).toBe(4);
});

test("string operations", () => {
  expect("hello".toUpperCase()).toBe("HELLO");
});

test("async operation", async () => {
  const result = await new Promise<string>(resolve => {
    setTimeout(() => resolve("async works"), 10);
  });
  expect(result).toBe("async works");
});

test("Bun APIs", () => {
  expect(Bun.version).toBeDefined();
  expect(typeof Bun.version).toBe("string");
});

test("file operations", async () => {
  const file = Bun.file("package.json");
  expect(await file.exists()).toBe(true);
  
  const text = await file.text();
  const json = JSON.parse(text);
  expect(json.name).toBe("bun-termux-example");
});

test("environment variables", () => {
  // Environment variables may not be available through grun
  expect(process.platform).toBe("linux");
  expect(process.arch).toBe("arm64");
  // HOME may be undefined in grun context
  if (process.env.HOME) {
    expect(typeof process.env.HOME).toBe("string");
  }
});