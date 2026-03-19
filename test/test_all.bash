#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_install_tests() {
	source "$SCRIPT_DIR/test_lib_install.bash"
	test_lib_install_main
}

run_remove_tests() {
	source "$SCRIPT_DIR/test_lib_remove.bash"
	test_lib_remove_main
}

run_update_tests() {
	source "$SCRIPT_DIR/test_lib_update.bash"
	test_lib_update_main
}

run_create_tests() {
	source "$SCRIPT_DIR/test_lib_create_project.bash"
	test_lib_create_project_main
}

run_CLI_install_tests() {
    source "$SCRIPT_DIR/test_cli_install.bash"
    test_cli_install_main
}

test_all_main() {
	echo -e "\e[1;36m[TEST]:\e[0m Running all tests..."
	run_install_tests
	run_remove_tests
	run_update_tests
	run_create_tests
	run_CLI_install_tests
	echo -e "\e[1;32m[TEST]:\e[0m All tests passed!!!"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	test_all_main "$@"
fi
