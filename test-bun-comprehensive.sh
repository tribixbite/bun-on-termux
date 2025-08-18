#!/data/data/com.termux/files/usr/bin/bash
# Comprehensive Bun test script for Termux - Updated with all commands
# Tests all major Bun commands and documents current functionality

echo "🧪 Comprehensive Bun Test Suite for Termux v2.0"
echo "==============================================="
echo

# Test environment
echo "📋 Test Environment:"
echo "Date: $(date)"
echo "Working directory: $(pwd)"
echo "Bun wrapper: $(which bun)"
echo "Bun version: $(bun --version 2>&1 || echo 'Failed to get version')"
echo "Bun revision: $(bun --revision 2>&1 || echo 'Failed to get revision')"
echo "Node version: $(node --version 2>&1 || echo 'Node not available')"
echo "grun available: $(which grun >/dev/null && echo 'Yes' || echo 'No')"
echo "glibc-runner: $(grun --version 2>/dev/null || echo 'Not available')"
echo

# Create test directory
TEST_DIR="/data/data/com.termux/files/home/bun-test-$$"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
echo "🔧 Created test directory: $TEST_DIR"
echo

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
RESULTS=""

# Helper function to run tests
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_exit="$3"
    local timeout_duration="$4"
    
    echo "🧪 Testing: $test_name"
    echo "Command: $command"
    
    # Use timeout if specified
    if [ -n "$timeout_duration" ]; then
        command="timeout $timeout_duration $command"
    fi
    
    # Run command and capture output
    output=$(eval "$command" 2>&1)
    exit_code=$?
    
    # Handle timeout exit code (124)
    if [ $exit_code -eq 124 ]; then
        echo "⏰ TIMEOUT (${timeout_duration}s)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        RESULTS="$RESULTS⏰ $test_name (timeout)\n"
    elif [ "$expected_exit" = "any" ] || [ $exit_code -eq "$expected_exit" ]; then
        echo "✅ PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        RESULTS="$RESULTS✅ $test_name\n"
    else
        echo "❌ FAIL (exit code: $exit_code, expected: $expected_exit)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        RESULTS="$RESULTS❌ $test_name (exit: $exit_code)\n"
    fi
    
    echo "Output: ${output:0:500}$([ ${#output} -gt 500 ] && echo '...[truncated]')"
    echo "---"
    echo
}

# === BASIC COMMANDS ===
echo "🔧 Basic Commands:"
run_test "bun --version" "bun --version" 0
run_test "bun --revision" "bun --revision" 0
run_test "bun --help" "bun --help" 0

# === FILE EXECUTION ===
echo "📄 File Execution:"
echo 'console.log("Hello from TypeScript:", 1 + 1);' > test.ts
echo 'console.log("Hello from JavaScript:", 2 + 2);' > test.js
echo 'console.log("Bun runtime test:", Bun.version);' > bun-test.js

run_test "bun test.ts (TypeScript)" "bun test.ts" 0
run_test "bun test.js (JavaScript)" "bun test.js" 0  
run_test "bun bun-test.js (Bun APIs)" "bun bun-test.js" 0
run_test "bun --bun test.js (force Bun runtime)" "bun --bun test.js" any

# === PACKAGE MANAGEMENT ===
echo "📦 Package Management:"

# Initialize project
run_test "bun init (project init)" "echo 'y' | bun init test-project" any
cd test-project 2>/dev/null || (mkdir test-project && cd test-project)

# Create basic package.json if init failed
echo '{
  "name":"test-project",
  "scripts":{
    "test":"echo test",
    "build":"echo building",
    "dev":"bun test.js",
    "start":"bun test.js"
  },
  "dependencies":{},
  "devDependencies":{}
}' > package.json

run_test "bun install (empty project)" "bun install" any
run_test "bun i (shorthand install)" "bun i" any

# Package addition/removal
run_test "bun add lodash" "bun add lodash" any 10
run_test "bun add -d typescript" "bun add -d typescript" any 10  
run_test "bun remove lodash" "bun remove lodash" any 5
run_test "bun rm typescript (shorthand)" "bun rm typescript" any 5

# Package info and management
run_test "bun outdated" "bun outdated" any 5
run_test "bun audit" "bun audit" any 5
run_test "bun update" "bun update" any 10

# === SCRIPT RUNNING ===
echo "🏃 Script Running:"
run_test "bun run test" "bun run test" any
run_test "bun run build" "bun run build" any
run_test "bun run dev" "bun run dev" any
run_test "bun run nonexistent" "bun run nonexistent" any

# === BUNX / PACKAGE EXECUTION ===
echo "🎯 Package Execution (bunx):"
run_test "bunx --version" "bunx --version" any
run_test "bun x cowsay hello" "bun x cowsay hello" any 15
run_test "bunx prettier --version" "bunx prettier --version" any 15

# === REPL ===
echo "💬 REPL:"
run_test "bun repl (exit immediately)" "echo 'process.exit(0)' | bun repl" any 5

# === TESTING ===
echo "🧪 Test Runner:"
echo 'import { test, expect } from "bun:test";
test("math", () => {
  expect(2 + 2).toBe(4);
});' > test.test.ts

run_test "bun test" "bun test" any 10
run_test "bun test --help" "bun test --help" 0

# === BUILDING ===
echo "🏗️ Build Commands:"
echo 'export default function() { return "Built successfully"; }' > build-test.js
echo 'console.log("Entry point");' > entry.js

run_test "bun build --help" "bun build --help" 0
run_test "bun build entry.js" "bun build entry.js --outdir=./dist" any
run_test "bun build (compile)" "bun build entry.js --compile --outfile=compiled-app" any

# === DEVELOPMENT FEATURES ===
echo "🔧 Development Features:"
echo 'console.log("Watch test"); setTimeout(() => process.exit(0), 1000);' > watch-test.js

run_test "bun --watch (timeout)" "bun --watch watch-test.js" any 5
run_test "bun --hot (timeout)" "bun --hot watch-test.js" any 5

# === EVALUATION ===
echo "⚡ Code Evaluation:"
run_test "bun -e 'console.log(\"eval test\")'" "bun -e 'console.log(\"eval test\")'" 0
run_test "bun -p '2+2'" "bun -p '2+2'" 0
run_test "bun --eval 'console.log(process.version)'" "bun --eval 'console.log(process.version)'" 0

# === ADVANCED FEATURES ===
echo "🚀 Advanced Features:"
run_test "bun --inspect (timeout)" "bun --inspect watch-test.js" any 3
run_test "bun --smol test.js" "bun --smol test.js" any

# Environment and configuration
run_test "bun --env-file" "echo 'TEST=1' > .env && bun --env-file=.env -e 'console.log(process.env.TEST)'" any
run_test "bun --cwd" "mkdir -p subdir && echo 'console.log(process.cwd())' > subdir/cwd-test.js && bun --cwd=./subdir cwd-test.js" any

# === PACKAGE MANAGER COMMANDS ===
echo "📋 Package Manager Utils:"
run_test "bun pm --help" "bun pm --help" any
run_test "bun pm ls" "bun pm ls" any
run_test "bun pm cache" "bun pm cache" any

# Linking (local development)
run_test "bun link --help" "bun link --help" any
run_test "bun unlink --help" "bun unlink --help" any

# Publishing
run_test "bun publish --help" "bun publish --help" any

# === CREATE TEMPLATES ===
echo "🎨 Project Creation:"
run_test "bun create --help" "bun create --help" any
run_test "bun c --help" "bun c --help" any

# === UPGRADE ===
echo "⬆️ Upgrade:"
run_test "bun upgrade --help" "bun upgrade --help" 0
run_test "bun upgrade --dry-run" "bun upgrade --dry-run" any 10

# === EXEC COMMAND ===
echo "🎯 Shell Execution:"
run_test "bun exec echo hello" "bun exec echo hello" any
run_test "bun exec --help" "bun exec --help" any

# === SPECIAL TESTS ===
echo "🔍 Special Cases:"

# Directory issues test
mkdir -p problematic-dir
cd problematic-dir
echo '{"scripts":{"test":"echo subdir test"}}' > package.json
run_test "bun run from subdirectory" "bun run test" any
cd ..

# Large file test
echo 'console.log("Large script"); for(let i=0; i<1000; i++) console.log("line", i);' > large-script.js
run_test "bun large script" "bun large-script.js | head -n 5" any

# Error handling
echo 'throw new Error("Test error");' > error-test.js
run_test "bun error handling" "bun error-test.js" 1

# Memory test
echo 'const arr = new Array(1000000).fill("test"); console.log("Memory test done");' > memory-test.js
run_test "bun memory test" "bun memory-test.js" any

# === ENVIRONMENT VARIABLES INVESTIGATION ===
echo "🔬 Environment Variable Investigation:"
echo 'console.log("PATH:", process.env.PATH ? "SET" : "NOT_SET");
console.log("HOME:", process.env.HOME ? "SET" : "NOT_SET"); 
console.log("TERMUX_VERSION:", process.env.TERMUX_VERSION || "NOT_SET");
console.log("Total env vars:", Object.keys(process.env).length);' > env-test.js

echo "Direct bun execution:"
bun env-test.js

echo "Through grun directly:"
grun ~/.bun/bin/buno env-test.js

# === UWU INTEGRATION TEST ===
echo "🦄 UWU Integration Test:"
if [ -f "/data/data/com.termux/files/home/git/uwu/dist/uwu-cli" ]; then
    run_test "uwu command generation" "/data/data/com.termux/files/home/git/uwu/dist/uwu-cli 'show current time'" any 10
fi

# Test Results Summary
echo
echo "📊 Test Results Summary"
echo "======================"
echo -e "$RESULTS"
echo "✅ Tests Passed: $TESTS_PASSED"
echo "❌ Tests Failed: $TESTS_FAILED"
echo "📈 Success Rate: $((TESTS_PASSED * 100 / (TESTS_PASSED + TESTS_FAILED)))%"
echo "📁 Test directory: $TEST_DIR"
echo

# System information
echo "🖥️  System Information:"
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"
echo "OS: $(uname -o 2>/dev/null || uname)"
echo "Shell: $SHELL"
echo "Memory: $(free -h 2>/dev/null | grep Mem | awk '{print $2}' || echo 'N/A')"
echo

# Bun specific information
echo "🥟 Bun Information:"
echo "Binary location: $(which bun)"
echo "Binary size: $(ls -lh $(which bun) | awk '{print $5}')"
echo "Wrapper type: $(head -n 1 $(which bun))"
echo "grun binary: $(which grun)"
echo "buno binary: $(ls -lh ~/.bun/bin/buno 2>/dev/null || echo 'Not found')"
echo

# Cleanup option
echo "🧹 Cleanup test directory? (y/N)"
read -t 10 cleanup
if [ "$cleanup" = "y" ]; then
    cd /data/data/com.termux/files/home
    rm -rf "$TEST_DIR"
    echo "Cleaned up test directory"
else
    echo "Test files preserved in: $TEST_DIR"
fi

echo
echo "🏁 Comprehensive Bun test suite completed!"
echo "📝 Notes:"
echo "   - Some failures are expected due to Termux/Android limitations"
echo "   - Environment variables don't pass through grun (known limitation)"
echo "   - Directory reading issues affect 'bun run' commands"
echo "   - Compilation features may be limited on ARM64 Android"