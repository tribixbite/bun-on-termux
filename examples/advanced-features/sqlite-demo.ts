#!/usr/bin/env bun
// SQLite database demonstration for Bun on Termux

import chalk from "chalk";
import { Database } from "bun:sqlite";

console.log(chalk.blue("🗄️ SQLite demo on Termux...\n"));

// Create in-memory database for demo
const db = new Database(":memory:");

// Create table
console.log(chalk.gray("Creating table..."));
db.run(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  )
`);

// Insert data
console.log(chalk.gray("Inserting demo data..."));
const insertUser = db.prepare("INSERT INTO users (name, email) VALUES (?, ?)");

const users = [
  ["Alice Johnson", "alice@example.com"],
  ["Bob Smith", "bob@example.com"],
  ["Charlie Brown", "charlie@example.com"],
  ["Diana Wilson", "diana@example.com"]
];

for (const [name, email] of users) {
  insertUser.run(name, email);
}

// Query data
console.log(chalk.green("📋 All users:"));
const allUsers = db.prepare("SELECT * FROM users").all();
console.table(allUsers);

// Query with parameters
console.log(chalk.green("🔍 Users with 'o' in name:"));
const searchUsers = db.prepare("SELECT name, email FROM users WHERE name LIKE ?").all("%o%");
console.table(searchUsers);

// Count records
const count = db.prepare("SELECT COUNT(*) as total FROM users").get() as { total: number };
console.log(chalk.yellow(`📊 Total users: ${count.total}`));

// Demonstrate transactions
console.log(chalk.gray("\nTesting transaction..."));
const transaction = db.transaction((users: Array<[string, string]>) => {
  const insert = db.prepare("INSERT INTO users (name, email) VALUES (?, ?)");
  for (const [name, email] of users) {
    insert.run(name, email);
  }
});

try {
  transaction([
    ["Eve Garcia", "eve@example.com"],
    ["Frank Miller", "frank@example.com"]
  ]);
  console.log(chalk.green("✅ Transaction completed"));
} catch (error) {
  console.error(chalk.red("❌ Transaction failed:"), error);
}

// Final count
const finalCount = db.prepare("SELECT COUNT(*) as total FROM users").get() as { total: number };
console.log(chalk.yellow(`📊 Final user count: ${finalCount.total}`));

// Performance test
console.log(chalk.gray("\nPerformance test..."));
const start = performance.now();

const insertMany = db.prepare("INSERT INTO users (name, email) VALUES (?, ?)");
const massInsert = db.transaction(() => {
  for (let i = 0; i < 1000; i++) {
    insertMany.run(`User ${i}`, `user${i}@test.com`);
  }
});

massInsert();
const duration = performance.now() - start;

console.log(chalk.green(`⚡ Inserted 1000 records in ${Math.round(duration)}ms`));

// Final stats
const stats = db.prepare(`
  SELECT 
    COUNT(*) as total_users,
    MAX(created_at) as latest_user,
    MIN(created_at) as earliest_user
  FROM users
`).get();

console.log(chalk.blue("\n📈 Database Statistics:"));
console.log(JSON.stringify(stats, null, 2));

db.close();
console.log(chalk.green("\n✅ SQLite demo completed!"));