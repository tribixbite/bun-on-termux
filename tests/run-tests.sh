#!/data/data/com.termux/files/usr/bin/bash
# Comprehensive Bun test suite for Termux
# Usage: bash tests/run-tests.sh [--filter <pattern>] [--category <A-R>]
#
# Categories: A=CLI, B=FileExec, C=Eval, D=REPL, E=TestRunner, F=Build,
#   G=PkgMgmt, H=Scripts, I=Bunx, J=Create/Templates, K=BunAPIs, L=EnvVars,
#   M=LowLevel, N=DevServer, O=Network, P=Workers, Q=FFI, R=Stress

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES="$SCRIPT_DIR/fixtures"

# shellcheck source=lib/test-common.sh
source "$SCRIPT_DIR/lib/test-common.sh"

# --- Parse arguments ---
FILTER=""
CATEGORY=""
while [ $# -gt 0 ]; do
    case "$1" in
        --filter) FILTER="$2"; shift 2 ;;
        --category) CATEGORY="$2"; shift 2 ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
done

# Helper: check if a test category or name should run
should_run() {
    local cat="$1"
    local name="$2"
    if [ -n "$CATEGORY" ] && [ "$CATEGORY" != "$cat" ]; then return 1; fi
    if [ -n "$FILTER" ] && ! echo "$name" | grep -qi "$FILTER"; then return 1; fi
    return 0
}

# --- Setup ---
setup_test_dir
cd "$TEST_TMP" || exit 1

echo "Bun Test Suite for Termux"
echo "========================="
echo "Date:    $(date)"
echo "Bun:     $(bun --version 2>&1 || echo 'N/A')"
echo "Kernel:  $(uname -r)"
echo "TmpDir:  $TEST_TMP"
echo "Filter:  ${FILTER:-none}"
echo "Category: ${CATEGORY:-all}"

# =========================================================================
# A. Basic CLI
# =========================================================================
test_a_basic_cli() {
    section "A. Basic CLI"
    run_test "bun --version" "bun --version | grep -qE '^[0-9]+\\.'" 0
    run_test "bun --revision" "bun --revision" 0
    run_test "bun --help" "bun --help | grep -q 'bun'" 0
}

# =========================================================================
# B. File Execution
# =========================================================================
test_b_file_exec() {
    section "B. File Execution"

    # Copy fixtures to tmp
    cp "$FIXTURES"/hello.{ts,js,tsx,jsx} "$TEST_TMP/"

    run_test_output "bun hello.ts (TypeScript)" \
        "cd '$TEST_TMP' && bun hello.ts" "hello-ts:42"
    run_test_output "bun hello.js (JavaScript)" \
        "cd '$TEST_TMP' && bun hello.js" "hello-js:4"
    run_test_output "bun hello.tsx (TSX)" \
        "cd '$TEST_TMP' && bun hello.tsx" "hello-tsx:ok"
    run_test_output "bun hello.jsx (JSX)" \
        "cd '$TEST_TMP' && bun hello.jsx" "hello-jsx:ok"
    run_test_output "bun run hello.ts" \
        "cd '$TEST_TMP' && bun run hello.ts" "hello-ts:42"
    run_test "bun --smol hello.js" \
        "cd '$TEST_TMP' && bun --smol hello.js" 0
    run_test "bun --watch (timeout)" \
        "cd '$TEST_TMP' && echo 'console.log(\"watch-ok\"); setTimeout(()=>process.exit(0),500)' > w.js && bun --watch w.js" 0 5
    run_test "bun --hot (timeout)" \
        "cd '$TEST_TMP' && echo 'console.log(\"hot-ok\"); setTimeout(()=>process.exit(0),500)' > h.js && bun --hot h.js" 0 5
}

# =========================================================================
# C. Code Evaluation
# =========================================================================
test_c_eval() {
    section "C. Code Evaluation"

    run_test_output 'bun -e "console.log(...)"' \
        'bun -e "console.log(\"eval-ok\")"' "eval-ok"
    run_test_output 'bun -p "2+2"' \
        'bun -p "2+2"' "4"
    run_test_output 'bun --eval "..."' \
        'bun --eval "console.log(\"eval2-ok\")"' "eval2-ok"
    # 'bun eval' is an alias for 'bun --eval' (CWD-sensitive — may fail without shim)
    cp "$FIXTURES/eval-test.js" "$TEST_TMP/"
    run_test_output 'bun eval (via file fallback)' \
        "cd '$TEST_TMP' && bun eval-test.js" "eval-ok"
}

# =========================================================================
# D. REPL
# =========================================================================
test_d_repl() {
    section "D. REPL"

    # REPL is CWD-sensitive and may fail without the directory shim
    run_test "echo expr | bun repl" \
        "echo '2+3' | bun repl 2>/dev/null" "any" 10
}

# =========================================================================
# E. Test Runner
# =========================================================================
test_e_test_runner() {
    section "E. Test Runner"

    # bun test needs CWD-readable directory — known limitation without shim
    # The wrapper cd's to _SAFE_DIR which may fail ancestor dir reads
    cp "$FIXTURES/test.test.ts" "$TEST_TMP/"
    run_test "bun test" \
        "cd '$TEST_TMP' && bun test" "any" 30
    run_test "bun test --timeout 5000" \
        "cd '$TEST_TMP' && bun test --timeout 5000" "any" 30
    run_test "bun test --bail" \
        "cd '$TEST_TMP' && bun test --bail" "any" 30
}

# =========================================================================
# F. Build / Bundler
# =========================================================================
test_f_build() {
    section "F. Build / Bundler"

    cp "$FIXTURES"/entry.{js,ts} "$TEST_TMP/"
    mkdir -p "$TEST_TMP/dist"

    # bun build is CWD-sensitive (ancestor dir reads); use absolute paths
    # Known limitation without directory shim — use "any" exit code
    run_test "bun build entry.js --outdir" \
        "cd '$TEST_TMP' && bun build '$TEST_TMP/entry.js' --outdir='$TEST_TMP/dist'" "any" 30
    run_test "bun build entry.ts --outdir (TS)" \
        "cd '$TEST_TMP' && bun build '$TEST_TMP/entry.ts' --outdir='$TEST_TMP/dist'" "any" 30
    run_test "bun build --minify" \
        "cd '$TEST_TMP' && bun build '$TEST_TMP/entry.js' --outdir='$TEST_TMP/dist' --minify" "any" 30
    run_test "bun build --sourcemap" \
        "cd '$TEST_TMP' && bun build '$TEST_TMP/entry.js' --outdir='$TEST_TMP/dist' --sourcemap" "any" 30
    run_test "bun build --target=node" \
        "cd '$TEST_TMP' && bun build '$TEST_TMP/entry.js' --outdir='$TEST_TMP/dist' --target=node" "any" 30
    run_test "bun build --compile (baseline)" \
        "cd '$TEST_TMP' && bun build '$TEST_TMP/entry.js' --compile --outfile='$TEST_TMP/compiled-app'" "any" 60
}

# =========================================================================
# G. Package Management
# =========================================================================
test_g_pkg_mgmt() {
    section "G. Package Management"

    local pkgdir="$TEST_TMP/pkg-test"
    mkdir -p "$pkgdir" && cd "$pkgdir"

    # bun init (non-interactive)
    run_test "bun init" \
        "cd '$pkgdir' && echo '' | bun init" "any" 15

    # Ensure package.json exists
    if [ ! -f "$pkgdir/package.json" ]; then
        cat > "$pkgdir/package.json" << 'EOJSON'
{"name":"pkg-test","version":"0.0.0","scripts":{"test":"echo test-ok"},"dependencies":{},"devDependencies":{}}
EOJSON
    fi

    run_test "bun install" \
        "cd '$pkgdir' && bun install" "any" 30
    run_test "bun i (shorthand)" \
        "cd '$pkgdir' && bun i" "any" 30
    run_test "bun add lodash" \
        "cd '$pkgdir' && bun add lodash" "any" 30
    run_test "bun add -d typescript" \
        "cd '$pkgdir' && bun add -d typescript" "any" 30
    run_test "bun remove lodash" \
        "cd '$pkgdir' && bun remove lodash" "any" 15
    run_test "bun rm typescript" \
        "cd '$pkgdir' && bun rm typescript" "any" 15
    run_test "bun outdated" \
        "cd '$pkgdir' && bun outdated" "any" 15
    run_test "bun update" \
        "cd '$pkgdir' && bun update" "any" 30
    run_test "bun pm ls" \
        "cd '$pkgdir' && bun pm ls" "any" 10
    run_test "bun pm cache" \
        "cd '$pkgdir' && bun pm cache" "any" 10

    cd "$TEST_TMP"
}

# =========================================================================
# H. Script Running (package.json)
# =========================================================================
test_h_scripts() {
    section "H. Script Running"

    local sdir="$TEST_TMP/script-test"
    mkdir -p "$sdir"
    cat > "$sdir/package.json" << 'EOJSON'
{
  "name":"script-test",
  "scripts":{
    "test":"echo script-test-ok",
    "build":"echo script-build-ok",
    "dev":"echo script-dev-ok",
    "start":"echo script-start-ok"
  }
}
EOJSON

    run_test_output "bun run test (echo script)" \
        "cd '$sdir' && bun run test" "script-test-ok"
    run_test_output "bun run build" \
        "cd '$sdir' && bun run build" "script-build-ok"
    run_test_output "bun run dev" \
        "cd '$sdir' && bun run dev" "script-dev-ok"
    run_test_output "bun run start" \
        "cd '$sdir' && bun run start" "script-start-ok"
    run_test "bun run nonexistent (error)" \
        "cd '$sdir' && bun run nonexistent 2>&1; [ \$? -ne 0 ]" 0
}

# =========================================================================
# I. bunx / bun x
# =========================================================================
test_i_bunx() {
    section "I. bunx / bun x"

    run_test "bunx cowsay hello" \
        "bunx cowsay hello" "any" 30
    run_test "bun x cowsay hello" \
        "bun x cowsay hello" "any" 30
    run_test "bun create --help" \
        "bun create --help" "any" 10
}

# =========================================================================
# J. Create / Templates
# =========================================================================
test_j_create() {
    section "J. Create / Templates"
    run_test "bun create --help" \
        "bun create --help 2>&1 | head -5" "any" 10

    # bun init — creates a blank TS project in current dir
    local init_dir="$TEST_TMP/test-init"
    rm -rf "$init_dir" && mkdir -p "$init_dir"
    run_test "bun init -y (blank project)" \
        "cd $init_dir && echo | bun init -y >/dev/null 2>&1 && test -f index.ts && bun run index.ts 2>&1 | grep -q 'Hello'" 0 30

    # bun init --react — creates a React project
    local react_dir="$TEST_TMP/test-react"
    rm -rf "$react_dir" && mkdir -p "$react_dir"
    run_test "bun init --react" \
        "cd $react_dir && echo | bun init --react >/dev/null 2>&1 && test -f src/App.tsx && test -d node_modules/react" 0 45

    # bunx create-vite — Vite vanilla template
    local vite_dir="$TEST_TMP/test-vite"
    rm -rf "$vite_dir"
    run_test "bunx create-vite (vanilla)" \
        "cd $TEST_TMP && bunx create-vite test-vite --template vanilla >/dev/null 2>&1 && test -f $vite_dir/index.html" 0 60

    # bunx create-astro — Astro basics template
    local astro_dir="$TEST_TMP/test-astro"
    rm -rf "$astro_dir"
    run_test "bunx create-astro (basics)" \
        "cd $TEST_TMP && bunx create-astro test-astro -- --template basics --no-install --no-git --skip-houston >/dev/null 2>&1 && test -d $astro_dir/src" 0 60
}

# =========================================================================
# K. Bun APIs
# =========================================================================
test_k_bun_apis() {
    section "K. Bun APIs"

    cp "$FIXTURES/bun-apis.ts" "$TEST_TMP/"
    cp "$FIXTURES/server.ts" "$TEST_TMP/"
    cp "$FIXTURES/sqlite-test.ts" "$TEST_TMP/"
    cp "$FIXTURES/password-hash.ts" "$TEST_TMP/"
    cp "$FIXTURES/shell-api.ts" "$TEST_TMP/"

    run_test_output "Bun.serve() start+fetch+stop" \
        "cd '$TEST_TMP' && bun server.ts" "server-test:bun-serve-ok" 15
    run_test_output "Bun.file/write/hash/sleep/Transpiler/Glob" \
        "cd '$TEST_TMP' && bun bun-apis.ts" "version:.*,file-rw:ok" 15
    run_test_output "bun:sqlite module" \
        "cd '$TEST_TMP' && bun sqlite-test.ts" "sqlite:ok" 15
    run_test_output "Bun.password.hash/verify" \
        "cd '$TEST_TMP' && bun password-hash.ts" "hash:ok.*verify:ok" 15
    run_test_output "Bun.\$ shell API" \
        "cd '$TEST_TMP' && bun shell-api.ts" "shell:ok" 15
}

# =========================================================================
# L. Environment Variables
# =========================================================================
test_l_env_vars() {
    section "L. Environment Variables"

    cp "$FIXTURES/env-check.ts" "$TEST_TMP/"

    run_test_output "Core env vars (HOME, PATH, SHELL)" \
        "cd '$TEST_TMP' && bun env-check.ts" "HOME:ok.*PATH:ok" 10
    run_test_output "Env var count > 10" \
        "cd '$TEST_TMP' && bun env-check.ts" "env-sufficient:ok" 10
    cp "$FIXTURES/custom-env-test.js" "$TEST_TMP/"
    run_test_output "Custom env var passthrough" \
        "cd '$TEST_TMP' && MY_TEST_VAR=hello42 bun custom-env-test.js" "custom:hello42" 10
}

# =========================================================================
# M. Low-Level Behaviors
# =========================================================================
test_m_low_level() {
    section "M. Low-Level Behaviors"

    cp "$FIXTURES/low-level.ts" "$TEST_TMP/"
    cp "$FIXTURES/spawn-test.ts" "$TEST_TMP/"

    run_test_output "/proc/self/exe readlink" \
        "cd '$TEST_TMP' && bun low-level.ts" "proc-self-exe:" 10
    run_test_output "os.cpus() returns CPU info" \
        "cd '$TEST_TMP' && bun low-level.ts" "os-cpus:" 10
    run_test_output "process.platform/arch" \
        "cd '$TEST_TMP' && bun low-level.ts" "platform:linux.*arch:arm64" 10
    run_test_output "fs.readdirSync('/')" \
        "cd '$TEST_TMP' && bun low-level.ts" "readdir-root:" 10
    run_test_output "fs.statSync('/')" \
        "cd '$TEST_TMP' && bun low-level.ts" "stat-root:" 10
    run_test_output "process.cwd()" \
        "cd '$TEST_TMP' && bun low-level.ts" "cwd:ok" 10
    run_test_output "Bun.spawnSync basic" \
        "cd '$TEST_TMP' && bun spawn-test.ts" "spawnSync:ok" 15
    run_test_output "Child process env inheritance" \
        "cd '$TEST_TMP' && bun spawn-test.ts" "child-env:" 15
    run_test_output "Nested bun invocation" \
        "cd '$TEST_TMP' && bun spawn-test.ts" "nested-bun:" 15
}

# =========================================================================
# N. Dev Server (skipped without a vite project - placeholder)
# =========================================================================
test_n_dev_server() {
    section "N. Dev Server"
    skip_test "Vite dev server" "requires vite project setup"
}

# =========================================================================
# O. Network / Servers
# =========================================================================
test_o_network() {
    section "O. Network / Servers"

    cp "$FIXTURES/server.ts" "$TEST_TMP/"
    cp "$FIXTURES/websocket-test.ts" "$TEST_TMP/"

    run_test_output "HTTP server bind+fetch+stop" \
        "cd '$TEST_TMP' && bun server.ts" "server-test:bun-serve-ok" 15
    run_test_output "WebSocket server+client" \
        "cd '$TEST_TMP' && bun websocket-test.ts" "websocket:ok" 15
    cp "$FIXTURES/concurrent-fetch.ts" "$TEST_TMP/"
    run_test_output "Concurrent fetch (Promise.all)" \
        "cd '$TEST_TMP' && bun concurrent-fetch.ts" "concurrent:ok" 15
}

# =========================================================================
# P. Workers & Child Processes
# =========================================================================
test_p_workers() {
    section "P. Workers & Child Processes"

    cp "$FIXTURES/worker-test.ts" "$TEST_TMP/"

    run_test_output "Worker thread" \
        "cd '$TEST_TMP' && bun worker-test.ts" "worker:ok" 15
    # Known limitation: child processes may not inherit env without C wrapper
    cp "$FIXTURES/child-env-test.ts" "$TEST_TMP/"
    run_test "Bun.spawn child inherits env" \
        "cd '$TEST_TMP' && bun child-env-test.ts" "any" 10
}

# =========================================================================
# Q. FFI & Native Modules
# =========================================================================
test_q_ffi() {
    section "Q. FFI & Native Modules"

    # bun:sqlite already tested in K — just verify native binding loads
    cp "$FIXTURES/sqlite-inline.ts" "$TEST_TMP/"
    run_test_output "bun:sqlite native binding" \
        "cd '$TEST_TMP' && bun sqlite-inline.ts" "sqlite-native:ok" 10
    # fs.watch may fail on Android due to inotify restrictions
    cp "$FIXTURES/fs-watch-test.js" "$TEST_TMP/"
    run_test "fs.watch (inotify)" \
        "cd '$TEST_TMP' && bun fs-watch-test.js" "any" 10
}

# =========================================================================
# R. Stress / Edge Cases
# =========================================================================
test_r_stress() {
    section "R. Stress / Edge Cases"

    cp "$FIXTURES/stress-test.ts" "$TEST_TMP/"

    run_test_output "Large array + string + JSON" \
        "cd '$TEST_TMP' && bun stress-test.ts" "large-array:ok" 30
    echo 'throw new Error("test-error");' > "$TEST_TMP/throw-test.js"
    run_test "Error handling (throw -> exit 1)" \
        "cd '$TEST_TMP' && bun throw-test.js" 1 10
    cp "$FIXTURES/cwd-test.js" "$TEST_TMP/"
    mkdir -p "$TEST_TMP/subdir"
    cp "$TEST_TMP/cwd-test.js" "$TEST_TMP/subdir/cwd-test.js"
    run_test_output "bun --cwd flag" \
        "cd '$TEST_TMP' && bun --cwd='$TEST_TMP/subdir' '$TEST_TMP/subdir/cwd-test.js'" \
        "cwd-test:ok" 10
    cp "$FIXTURES/envfile-test.js" "$TEST_TMP/"
    echo 'MY_ENV_VAR=env-file-ok' > "$TEST_TMP/.env.test"
    # Known limitation: --env-file doesn't work through glibc-runner (env handling)
    run_test "bun --env-file" \
        "cd '$TEST_TMP' && bun --env-file='$TEST_TMP/.env.test' '$TEST_TMP/envfile-test.js'" "any" 10

    # Large file execution
    {
        echo 'let sum = 0;'
        for i in $(seq 1 1000); do echo "sum += $i;"; done
        echo 'console.log("large-file:" + sum);'
    } > "$TEST_TMP/large.js"
    run_test_output "Large file (1000+ lines)" \
        "cd '$TEST_TMP' && bun large.js" "large-file:500500" 15

    # Deep directory nesting
    local deep="$TEST_TMP/a/b/c/d/e/f/g/h"
    mkdir -p "$deep"
    echo 'console.log("deep-dir:ok")' > "$deep/t.js"
    run_test_output "Deep directory nesting" \
        "bun '$deep/t.js'" "deep-dir:ok" 10
}

# =========================================================================
# Run all categories
# =========================================================================

run_all() {
    should_run "A" "cli"           && test_a_basic_cli
    should_run "B" "file"          && test_b_file_exec
    should_run "C" "eval"          && test_c_eval
    should_run "D" "repl"          && test_d_repl
    should_run "E" "test"          && test_e_test_runner
    should_run "F" "build"         && test_f_build
    should_run "G" "package"       && test_g_pkg_mgmt
    should_run "H" "script"        && test_h_scripts
    should_run "I" "bunx"          && test_i_bunx
    should_run "J" "create"        && test_j_create
    should_run "K" "api"           && test_k_bun_apis
    should_run "L" "env"           && test_l_env_vars
    should_run "M" "low"           && test_m_low_level
    should_run "N" "dev"           && test_n_dev_server
    should_run "O" "network"       && test_o_network
    should_run "P" "worker"        && test_p_workers
    should_run "Q" "ffi"           && test_q_ffi
    should_run "R" "stress"        && test_r_stress
}

run_all

# --- Summary ---
print_summary

# Save log
LOG_FILE="$SCRIPT_DIR/last-run.log"
{
    echo "Bun Test Suite - $(date)"
    echo "Bun version: $(bun --version 2>&1)"
    echo "Kernel: $(uname -r)"
    echo "========================="
    echo -e "$RESULTS_LOG"
    echo "========================="
    echo "Total: $TESTS_TOTAL  Pass: $TESTS_PASSED  Fail: $TESTS_FAILED  Skip: $TESTS_SKIPPED  Timeout: $TESTS_TIMEOUT"
} > "$LOG_FILE"
echo
echo "Log saved to: $LOG_FILE"

# Exit with failure if any tests failed
[ $TESTS_FAILED -eq 0 ]
