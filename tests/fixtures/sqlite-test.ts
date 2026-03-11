// bun:sqlite module test
import { Database } from "bun:sqlite";

const db = new Database(":memory:");

db.run("CREATE TABLE test (id INTEGER PRIMARY KEY, value TEXT)");
db.run("INSERT INTO test (value) VALUES (?)", ["hello-sqlite"]);

const row = db.query("SELECT value FROM test WHERE id = 1").get() as any;
const ok = row?.value === "hello-sqlite";

db.close();
console.log(`sqlite:${ok ? "ok" : "fail"}`);
