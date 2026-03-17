#!/usr/bin/env bash
# Used to test installer library functions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/test_asserts.bash"
source "$SCRIPT_DIR/../lib/internal/bashlib_install.bash"

# -----------------------------------------------------------------------------
# Test sandbox
# -----------------------------------------------------------------------------

TEST_ROOT=""
SRC_ROOT=""

setup_test_env() {
    TEST_ROOT="$(mktemp -d)"
    SRC_ROOT="$TEST_ROOT/source_tool"

    mkdir -p "$SRC_ROOT/lib"
    mkdir -p "$SRC_ROOT/libexec"

    cat > "$SRC_ROOT/tool.toml" <<EOF
[project]
tool = "mytool"
version = "0.1.0"
EOF

    cat > "$SRC_ROOT/mytool" <<'EOF'
#!/usr/bin/env bash
echo "hello from root tool"
EOF

    cat > "$SRC_ROOT/lib/helper.bash" <<'EOF'
#!/usr/bin/env bash
helper_func() { return 0; }
EOF

    cat > "$SRC_ROOT/libexec/mytool-subcmd" <<'EOF'
#!/usr/bin/env bash
echo "hello from libexec"
EOF

    chmod +x "$SRC_ROOT/mytool"
    chmod +x "$SRC_ROOT/lib/helper.bash"
    chmod +x "$SRC_ROOT/libexec/mytool-subcmd"
}

cleanup_test_env() {
    [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"

    # clean installed test artifacts
    rm -f "$HOME/.local/bin/mytool"
    rm -rf "$HOME/.local/lib/mytool"
    rm -rf "$HOME/.local/libexec/mytool"
}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

assert_installed_file() {
    local path="$1" msg="${2:-Expected file to exist: $1}"
    assert_exists "$path" "$msg"
    assert_file "$path" "$msg"
}

assert_installed_dir() {
    local path="$1" msg="${2:-Expected directory to exist: $1}"
    assert_exists "$path" "$msg"
    assert_directory "$path" "$msg"
}

# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------

test_move_to_lib() {
    local status=""

    echo "Testing move to lib..."
    cleanup_test_env
    setup_test_env

    _bashlib_move_to_lib "$SRC_ROOT" "$HOME/.local" "mytool" 0 > /dev/null 2>&1
    status="$?"

    assert_true "$status" "move_to_lib should succeed, got $status"
    assert_installed_dir "$HOME/.local/lib/mytool" "lib install dir should exist"
    assert_installed_file "$HOME/.local/lib/mytool/helper.bash" "lib file should be copied"
    assert_installed_file "$HOME/.local/lib/mytool/tool.toml" "tool metadata should be copied to lib dir"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m move_to_lib passed"
}

test_move_to_libexec() {
    local status=""

    echo "Testing move to libexec..."
    cleanup_test_env
    setup_test_env

    _bashlib_move_to_libexec "$SRC_ROOT" "$HOME/.local" "mytool" 0 > /dev/null 2>&1
    status="$?"

    assert_true "$status" "move_to_libexec should succeed, got $status"
    assert_installed_dir "$HOME/.local/libexec/mytool" "libexec install dir should exist"
    assert_installed_file "$HOME/.local/libexec/mytool/mytool-subcmd" "libexec file should be copied"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m move_to_libexec passed"
}

test_move_to_bin() {
    local status=""

    echo "Testing move to bin..."
    cleanup_test_env
    setup_test_env

    _bashlib_move_to_bin "$SRC_ROOT" "$HOME/.local" "mytool" 0 > /dev/null 2>&1
    status="$?"

    assert_true "$status" "move_to_bin should succeed, got $status"
    assert_installed_file "$HOME/.local/bin/mytool" "bin file should exist"
    assert_executable "$HOME/.local/bin/mytool" "bin file should be executable"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m move_to_bin passed"
}

test_install_from_source() {
    local status=""

    echo "Testing install from source..."
    cleanup_test_env
    setup_test_env

    bashlib_install_from_source "$SRC_ROOT" "$HOME/.local" 0 > /dev/null 2>&1
    status="$?"

    assert_true "$status" "install_from_source should succeed, got $status"

    assert_installed_file "$HOME/.local/bin/mytool" "installed bin tool missing"
    assert_installed_dir "$HOME/.local/lib/mytool" "installed lib dir missing"
    assert_installed_file "$HOME/.local/lib/mytool/helper.bash" "installed lib file missing"
    assert_installed_file "$HOME/.local/lib/mytool/tool.toml" "installed tool metadata missing"
    assert_installed_dir "$HOME/.local/libexec/mytool" "installed libexec dir missing"
    assert_installed_file "$HOME/.local/libexec/mytool/mytool-subcmd" "installed libexec file missing"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m install_from_source passed"
}

test_install_from_repo() {
    local status="" bad_repo=""

    echo "Testing install from repo..."
    cleanup_test_env
    setup_test_env

    bad_repo="$TEST_ROOT/does_not_exist"

    bashlib_install_from_repo "$bad_repo" "$HOME/.local" 0 > /dev/null 2>&1
    status="$?"

    assert_false "$status" "install_from_repo should fail on invalid repo path"

    cleanup_test_env
    echo -e "\e[1;32m[TEST]:\e[0m install_from_repo passed"
}

test_lib_install_main() {
    echo -e "\e[1;36m[TEST]:\e[0m Running installer tests..."

    test_move_to_lib
    test_move_to_libexec
    test_move_to_bin
    test_install_from_source
    test_install_from_repo

    echo -e "\e[1;32m[TEST]:\e[0m All installer tests passed!!!"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    test_lib_install_main "$@"
fi

