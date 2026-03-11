import { Database } from "bun:sqlite";
const db = new Database(":memory:");
db.close();
console.log("sqlite-native:ok");
