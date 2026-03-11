import { test, expect, describe } from "bun:test";

describe("basic math", () => {
    test("addition", () => {
        expect(2 + 2).toBe(4);
    });

    test("multiplication", () => {
        expect(3 * 7).toBe(21);
    });
});

describe("async", () => {
    test("setTimeout resolves", async () => {
        await new Promise(resolve => setTimeout(resolve, 10));
        expect(true).toBe(true);
    });
});
