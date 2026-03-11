#!/data/data/com.termux/files/usr/bin/bash
# Shared test helpers for bun-on-termux test suite
# Provides colored output, pass/fail tracking, temp dir management, cleanup

# --- Color output (disable if not a terminal) ---
if [ -t 1 ]; then
    C_RED='\033[0;31m'
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[0;33m'
    C_BLUE='\033[0;34m'
    C_CYAN='\033[0;36m'
    C_BOLD='\033[1m'
    C_RESET='\033[0m'
else
    C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_CYAN='' C_BOLD='' C_RESET=''
fi

# --- Counters ---
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
TESTS_TIMEOUT=0
TESTS_TOTAL=0
RESULTS_LOG=""

# --- Temp directory management ---
TEST_TMP=""

setup_test_dir() {
    TEST_TMP=$(mktemp -d "${TMPDIR:-/data/data/com.termux/files/home/.bun/tmp}/bun-test-XXXXXX")
    if [ ! -d "$TEST_TMP" ]; then
        echo "FATAL: could not create temp dir" >&2
        exit 1
    fi
}

cleanup_test_dir() {
    if [ -n "$TEST_TMP" ] && [ -d "$TEST_TMP" ]; then
        rm -rf "$TEST_TMP"
    fi
}

# Trap for cleanup on exit/interrupt
trap cleanup_test_dir EXIT INT TERM

# --- Test runner ---

# run_test <name> <command> [expected_exit] [timeout_sec]
#   expected_exit: 0 (default), "any" (any exit code), or specific number
#   timeout_sec: timeout in seconds (default: 30)
#   Exit code 124 from timeout counts as pass for expected-timeout tests
run_test() {
    local name="$1"
    local cmd="$2"
    local expected="${3:-0}"
    local timeout_sec="${4:-30}"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))

    # Print test name
    printf "  ${C_CYAN}%-60s${C_RESET} " "$name"

    # Run with timeout, capture stdout+stderr
    local output exit_code
    output=$(timeout "$timeout_sec" bash -c "$cmd" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 124 ]; then
        # Timeout: pass if the test is expected to timeout (timeout_sec < 30 implies
        # it's a long-running process test like --watch/--hot)
        TESTS_TIMEOUT=$((TESTS_TIMEOUT + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "${C_YELLOW}TIMEOUT${C_RESET}\n"
        RESULTS_LOG="${RESULTS_LOG}TIMEOUT  $name\n"
        return 0
    elif [ "$expected" = "any" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "${C_GREEN}PASS${C_RESET} (exit=$exit_code)\n"
        RESULTS_LOG="${RESULTS_LOG}PASS     $name (exit=$exit_code)\n"
        return 0
    elif [ "$exit_code" -eq "$expected" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "${C_GREEN}PASS${C_RESET}\n"
        RESULTS_LOG="${RESULTS_LOG}PASS     $name\n"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf "${C_RED}FAIL${C_RESET} (exit=$exit_code, expected=$expected)\n"
        # Show first 3 lines of output for failed tests
        if [ -n "$output" ]; then
            echo "$output" | head -3 | sed 's/^/    | /'
        fi
        RESULTS_LOG="${RESULTS_LOG}FAIL     $name (exit=$exit_code, expected=$expected)\n"
        return 1
    fi
}

# run_test_output <name> <command> <expected_pattern> [timeout_sec]
#   Passes if command exits 0 AND stdout matches the grep pattern
run_test_output() {
    local name="$1"
    local cmd="$2"
    local pattern="$3"
    local timeout_sec="${4:-30}"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    printf "  ${C_CYAN}%-60s${C_RESET} " "$name"

    local output exit_code
    output=$(timeout "$timeout_sec" bash -c "$cmd" 2>&1)
    exit_code=$?

    if [ $exit_code -eq 124 ]; then
        TESTS_TIMEOUT=$((TESTS_TIMEOUT + 1))
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "${C_YELLOW}TIMEOUT${C_RESET}\n"
        RESULTS_LOG="${RESULTS_LOG}TIMEOUT  $name\n"
        return 0
    fi

    if [ $exit_code -ne 0 ]; then
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf "${C_RED}FAIL${C_RESET} (exit=$exit_code)\n"
        echo "$output" | head -3 | sed 's/^/    | /'
        RESULTS_LOG="${RESULTS_LOG}FAIL     $name (exit=$exit_code)\n"
        return 1
    fi

    if echo "$output" | grep -qE "$pattern"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "${C_GREEN}PASS${C_RESET}\n"
        RESULTS_LOG="${RESULTS_LOG}PASS     $name\n"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf "${C_RED}FAIL${C_RESET} (pattern not found: $pattern)\n"
        echo "$output" | head -3 | sed 's/^/    | /'
        RESULTS_LOG="${RESULTS_LOG}FAIL     $name (pattern mismatch)\n"
        return 1
    fi
}

# skip_test <name> <reason>
skip_test() {
    local name="$1"
    local reason="$2"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    printf "  ${C_CYAN}%-60s${C_RESET} ${C_YELLOW}SKIP${C_RESET} ($reason)\n" "$name"
    RESULTS_LOG="${RESULTS_LOG}SKIP     $name ($reason)\n"
}

# --- Section headers ---
section() {
    echo
    printf "${C_BOLD}${C_BLUE}=== %s ===${C_RESET}\n" "$1"
}

# --- Summary ---
print_summary() {
    echo
    printf "${C_BOLD}========================================${C_RESET}\n"
    printf "${C_BOLD}  Test Summary${C_RESET}\n"
    printf "${C_BOLD}========================================${C_RESET}\n"
    printf "  Total:    %d\n" "$TESTS_TOTAL"
    printf "  ${C_GREEN}Passed:   %d${C_RESET}\n" "$TESTS_PASSED"
    printf "  ${C_RED}Failed:   %d${C_RESET}\n" "$TESTS_FAILED"
    printf "  ${C_YELLOW}Skipped:  %d${C_RESET}\n" "$TESTS_SKIPPED"
    printf "  ${C_YELLOW}Timeout:  %d${C_RESET} (counted as pass)\n" "$TESTS_TIMEOUT"
    if [ $TESTS_TOTAL -gt 0 ]; then
        local pct=$(( (TESTS_PASSED * 100) / TESTS_TOTAL ))
        printf "  Rate:     %d%%\n" "$pct"
    fi
    printf "${C_BOLD}========================================${C_RESET}\n"

    if [ $TESTS_FAILED -gt 0 ]; then
        echo
        printf "${C_RED}Failed tests:${C_RESET}\n"
        echo -e "$RESULTS_LOG" | grep "^FAIL" | sed 's/^/  /'
    fi
}

# --- Fixture helpers ---

# Create a minimal package.json in $TEST_TMP with given scripts
create_package_json() {
    local dir="${1:-$TEST_TMP}"
    local scripts="${2:-}"
    if [ -z "$scripts" ]; then
        scripts='"test":"echo test-ok","build":"echo build-ok","dev":"echo dev-ok","start":"echo start-ok"'
    fi
    cat > "$dir/package.json" << EOJSON
{
  "name": "bun-test-project",
  "version": "0.0.0",
  "scripts": { $scripts },
  "dependencies": {},
  "devDependencies": {}
}
EOJSON
}

# Write a fixture file to $TEST_TMP
write_fixture() {
    local filename="$1"
    local content="$2"
    echo "$content" > "$TEST_TMP/$filename"
}
