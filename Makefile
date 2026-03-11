# Bun on Termux — Build system for C wrapper and shim
#
# Targets:
#   all       - Build shim and wrapper
#   install   - Install to ~/.bun/{bin,lib}
#   uninstall - Remove installed components
#   test      - Run the test suite
#   clean     - Remove build artifacts

BUN_PREFIX := $(if $(BUN_INSTALL),$(BUN_INSTALL),$(HOME)/.bun)
BUN_BIN_DIR = $(BUN_PREFIX)/bin
BUN_LIB_DIR = $(BUN_PREFIX)/lib
BUN_TMP_DIR = $(BUN_PREFIX)/tmp

# Compiler settings
CFLAGS = -Wall -Wextra -Werror=implicit-function-declaration \
         -Werror=format-security -O2

# Shim: must link against glibc (cross-compiled for glibc target)
GLIBC_ROOT ?= /data/data/com.termux/files/usr/glibc
GLIBC_INC = $(GLIBC_ROOT)/include
GLIBC_LIB = $(GLIBC_ROOT)/lib

SHIM_CC = clang --target=aarch64-linux-gnu
SHIM_CFLAGS = $(CFLAGS) -shared -fPIC -nostdlib

# Wrapper: native Termux compilation (bionic libc)
WRAPPER_CC = clang
WRAPPER_CFLAGS = $(CFLAGS)

# Build artifacts
SHIM_SO = bun-shim.so
WRAPPER_BIN = bun-termux

all: $(SHIM_SO) $(WRAPPER_BIN)

$(SHIM_SO): src/shim.c
	@echo "  CC  $@ (glibc target)"
	@$(SHIM_CC) $(SHIM_CFLAGS) \
		-I$(GLIBC_INC) \
		-L$(GLIBC_LIB) \
		-Wl,-rpath,$(GLIBC_LIB) \
		-Wl,-rpath-link,$(GLIBC_LIB) \
		-o $@ $< \
		-l:libc.so.6 -l:libdl.so.2

$(WRAPPER_BIN): src/bun-termux.c
	@echo "  CC  $@ (native)"
	@$(WRAPPER_CC) $(WRAPPER_CFLAGS) -o $@ $<

install: all
	@echo "Installing to $(BUN_PREFIX)..."
	@mkdir -p $(BUN_BIN_DIR) $(BUN_LIB_DIR) $(BUN_TMP_DIR) $(BUN_TMP_DIR)/fake-root
	@cp $(WRAPPER_BIN) $(BUN_BIN_DIR)/$(WRAPPER_BIN)
	@chmod +x $(BUN_BIN_DIR)/$(WRAPPER_BIN)
	@cp $(SHIM_SO) $(BUN_LIB_DIR)/$(SHIM_SO)
	@echo "  Wrapper: $(BUN_BIN_DIR)/$(WRAPPER_BIN)"
	@echo "  Shim:    $(BUN_LIB_DIR)/$(SHIM_SO)"
	@echo "  Binary:  $(BUN_BIN_DIR)/buno"
	@echo "Installed."

uninstall:
	@echo "Uninstalling from $(BUN_PREFIX)..."
	@-rm -f "$(BUN_BIN_DIR)/$(WRAPPER_BIN)"
	@-rm -f "$(BUN_LIB_DIR)/$(SHIM_SO)"
	@echo "Uninstalled."

test: all install
	@bash tests/run-tests.sh

clean:
	@rm -f $(SHIM_SO) $(WRAPPER_BIN)
	@echo "Cleaned."

.PHONY: all install uninstall test clean
