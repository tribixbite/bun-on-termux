#!/usr/bin/env bun
// Cryptography demonstration for Bun on Termux

import chalk from "chalk";

console.log(chalk.blue("🔐 Cryptography demo on Termux...\n"));

// Hash functions
console.log(chalk.green("📝 Hash Functions:"));

const data = "Hello, Bun on Termux!";
console.log(chalk.gray(`Original data: "${data}"`));

// SHA-256
const sha256 = await Bun.hash(data, "sha256");
console.log(chalk.cyan("SHA-256:"), Buffer.from(sha256).toString("hex"));

// SHA-1
const sha1 = await Bun.hash(data, "sha1");
console.log(chalk.cyan("SHA-1:  "), Buffer.from(sha1).toString("hex"));

// MD5
const md5 = await Bun.hash(data, "md5");
console.log(chalk.cyan("MD5:    "), Buffer.from(md5).toString("hex"));

// Password hashing with Bun.password
console.log(chalk.green("\n🔒 Password Hashing:"));

const password = "mySecurePassword123!";
console.log(chalk.gray(`Password: "${password}"`));

const hashedPassword = await Bun.password.hash(password);
console.log(chalk.cyan("Hashed: "), hashedPassword);

// Verify password
const isValid = await Bun.password.verify(password, hashedPassword);
console.log(chalk.cyan("Verify: "), isValid ? chalk.green("✅ Valid") : chalk.red("❌ Invalid"));

// Test with wrong password
const wrongPassword = "wrongPassword";
const isWrong = await Bun.password.verify(wrongPassword, hashedPassword);
console.log(chalk.cyan("Wrong:  "), isWrong ? chalk.green("✅ Valid") : chalk.red("❌ Invalid"));

// Crypto API demonstrations
console.log(chalk.green("\n🔑 Web Crypto API:"));

// Generate random bytes
const randomBytes = crypto.getRandomValues(new Uint8Array(16));
console.log(chalk.cyan("Random bytes:"), Array.from(randomBytes).map(b => b.toString(16).padStart(2, '0')).join(''));

// Generate UUID
const uuid = crypto.randomUUID();
console.log(chalk.cyan("Random UUID:"), uuid);

// Subtle crypto operations
console.log(chalk.green("\n🔐 Subtle Crypto Operations:"));

// Generate key pair for RSA
const keyPair = await crypto.subtle.generateKey(
  {
    name: "RSA-PSS",
    modulusLength: 2048,
    publicExponent: new Uint8Array([1, 0, 1]),
    hash: "SHA-256",
  },
  true,
  ["sign", "verify"]
);

console.log(chalk.cyan("RSA key pair generated:"), "✅");

// Export public key
const publicKey = await crypto.subtle.exportKey("spki", keyPair.publicKey);
console.log(chalk.cyan("Public key size:"), publicKey.byteLength, "bytes");

// Sign and verify
const message = new TextEncoder().encode("Message to sign");
const signature = await crypto.subtle.sign(
  {
    name: "RSA-PSS",
    saltLength: 32,
  },
  keyPair.privateKey,
  message
);

console.log(chalk.cyan("Signature size:"), signature.byteLength, "bytes");

const verified = await crypto.subtle.verify(
  {
    name: "RSA-PSS",
    saltLength: 32,
  },
  keyPair.publicKey,
  signature,
  message
);

console.log(chalk.cyan("Signature valid:"), verified ? chalk.green("✅") : chalk.red("❌"));

// AES encryption
console.log(chalk.green("\n🔒 AES Encryption:"));

const aesKey = await crypto.subtle.generateKey(
  {
    name: "AES-GCM",
    length: 256,
  },
  true,
  ["encrypt", "decrypt"]
);

const plaintext = new TextEncoder().encode("Secret message for AES encryption");
const iv = crypto.getRandomValues(new Uint8Array(12));

const encrypted = await crypto.subtle.encrypt(
  {
    name: "AES-GCM",
    iv: iv
  },
  aesKey,
  plaintext
);

console.log(chalk.cyan("Original:"), new TextDecoder().decode(plaintext));
console.log(chalk.cyan("Encrypted size:"), encrypted.byteLength, "bytes");

const decrypted = await crypto.subtle.decrypt(
  {
    name: "AES-GCM",
    iv: iv
  },
  aesKey,
  encrypted
);

console.log(chalk.cyan("Decrypted:"), new TextDecoder().decode(decrypted));

// Base64 encoding/decoding
console.log(chalk.green("\n📄 Base64 Encoding:"));

const textToEncode = "Bun on Termux rocks! 🚀";
const base64Encoded = btoa(textToEncode);
const base64Decoded = atob(base64Encoded);

console.log(chalk.cyan("Original:"), textToEncode);
console.log(chalk.cyan("Base64:  "), base64Encoded);
console.log(chalk.cyan("Decoded: "), base64Decoded);

// Performance test
console.log(chalk.green("\n⚡ Crypto Performance:"));

const iterations = 1000;
const testData = "Performance test data for hashing";

const start = performance.now();
for (let i = 0; i < iterations; i++) {
  await Bun.hash(testData + i, "sha256");
}
const duration = performance.now() - start;

console.log(chalk.cyan(`SHA-256 x${iterations}:`), `${Math.round(duration)}ms`, `(${Math.round(iterations / (duration / 1000))} ops/sec)`);

console.log(chalk.green("\n✅ Cryptography demo completed!"));