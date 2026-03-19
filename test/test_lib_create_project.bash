#!/usr/bin/env bash
# Used to test create-project library functions

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/test_asserts.bash"
source "$SCRIPT_DIR/../lib/toml/toml_read.bash"
source "$SCRIPT_DIR/../lib/internal/bashlib_create.bash"

TEST_ROOT=""

setup_test_env() {
	TEST_ROOT="$(mktemp -d)"
}

cleanup_test_env() {
	if [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]]; then
		rm -rf "$TEST_ROOT"
	fi

	TEST_ROOT=""
}

test_create_mkdirs_creates_scaffold_dirs() {
	local status=""
	local project_dir=""

	echo "Testing create_mkdirs builds scaffold directories..."
	cleanup_test_env
	setup_test_env

	project_dir="$TEST_ROOT/my-new-tool"
	create_mkdirs "$project_dir" > /dev/null 2>&1
	status="$?"

	assert_true "$status" "create_mkdirs should succeed"
	assert_directory "$project_dir" "project dir should exist"
	assert_directory "$project_dir/lib" "lib dir should exist"
	assert_directory "$project_dir/lib/internal" "lib/internal dir should exist"
	assert_directory "$project_dir/libexec" "libexec dir should exist"
	assert_directory "$project_dir/man" "man dir should exist"

	cleanup_test_env
	echo -e "\e[1;32m[TEST]:\e[0m create_mkdirs_creates_scaffold_dirs passed"
}

test_create_mkdirs_fails_when_project_exists() {
	local status=""
	local project_dir=""

	echo "Testing create_mkdirs fails on existing project path..."
	cleanup_test_env
	setup_test_env

	project_dir="$TEST_ROOT/existing-project"
	mkdir -p "$project_dir"

	create_mkdirs "$project_dir" > /dev/null 2>&1
	status="$?"

	assert_false "$status" "create_mkdirs should fail if project path already exists"

	cleanup_test_env
	echo -e "\e[1;32m[TEST]:\e[0m create_mkdirs_fails_when_project_exists passed"
}

test_create_touch_files_creates_expected_files() {
	local status=""
	local project_dir=""
	local tool="mytool"

	echo "Testing create_touch_files creates all scaffold files..."
	cleanup_test_env
	setup_test_env

	project_dir="$TEST_ROOT/mytool-project"

	create_mkdirs "$project_dir" > /dev/null 2>&1
	create_touch_files "$project_dir" "$tool" "Test Author" "https://example.com/test/repo.git" > /dev/null 2>&1
	status="$?"

	assert_true "$status" "create_touch_files should succeed"
	assert_file "$project_dir/tool.toml" "tool.toml should exist"
	assert_file "$project_dir/$tool" "tool script should exist"
	assert_executable "$project_dir/$tool" "tool script should be executable"
	assert_file "$project_dir/lib/$tool.bash" "lib script should exist"
	assert_file "$project_dir/README.md" "README should exist"
	assert_file "$project_dir/.gitignore" ".gitignore should exist"

	cleanup_test_env
	echo -e "\e[1;32m[TEST]:\e[0m create_touch_files_creates_expected_files passed"
}

test_create_touch_files_writes_expected_toml() {
	local status=""
	local project_dir=""
	local project_name="mytool-project"
	local tool="mytool"
	local author="Test Author"
	local repo="https://example.com/test/repo.git"
	local value=""

	echo "Testing create_touch_files writes expected tool.toml values..."
	cleanup_test_env
	setup_test_env

	project_dir="$TEST_ROOT/$project_name"

	create_mkdirs "$project_dir" > /dev/null 2>&1
	create_touch_files "$project_dir" "$tool" "$author" "$repo" > /dev/null 2>&1
	status="$?"

	assert_true "$status" "create_touch_files should succeed before checking tool.toml"

	value="$(toml_read_key "$project_dir/tool.toml" "project" "project" 2>/dev/null)"
	assert_str_eq "$value" "$project_name" "tool.toml should include project name"

	value="$(toml_read_key "$project_dir/tool.toml" "project" "tool" 2>/dev/null)"
	assert_str_eq "$value" "$tool" "tool.toml should include project.tool"

	value="$(toml_read_key "$project_dir/tool.toml" "project" "author" 2>/dev/null)"
	assert_str_eq "$value" "$author" "tool.toml should include project.author"

	value="$(toml_read_key "$project_dir/tool.toml" "project" "repo" 2>/dev/null)"
	assert_str_eq "$value" "$repo" "tool.toml should include project.repo"

	value="$(toml_read_key "$project_dir/tool.toml" "directories" "lib" 2>/dev/null)"
	assert_str_eq "$value" "lib" "tool.toml should include directories.lib"

	value="$(toml_read_key "$project_dir/tool.toml" "directories" "libexec" 2>/dev/null)"
	assert_str_eq "$value" "libexec" "tool.toml should include directories.libexec"

	value="$(toml_read_key "$project_dir/tool.toml" "directories" "man" 2>/dev/null)"
	assert_str_eq "$value" "man" "tool.toml should include directories.man"

	cleanup_test_env
	echo -e "\e[1;32m[TEST]:\e[0m create_touch_files_writes_expected_toml passed"
}

test_lib_create_project_main() {
	echo -e "\e[1;36m[TEST]:\e[0m Running create-project tests..."

	test_create_mkdirs_creates_scaffold_dirs
	test_create_mkdirs_fails_when_project_exists
	test_create_touch_files_creates_expected_files
	test_create_touch_files_writes_expected_toml

	echo -e "\e[1;32m[TEST]:\e[0m All create-project tests passed!!!"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	test_lib_create_project_main "$@"
fi
