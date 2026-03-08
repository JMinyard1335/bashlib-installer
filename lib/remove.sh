#!/usr/bin/env bash
# Used to remove the given projects directory
#
# Projects are looked for in $HOME/.local/bin/
# If the project is not found the user is told
# and the program returns an error code.
# By default will search bin & lib. if you know
# where the
#
# Examples:
# remove [opts] <project-name>
# remove --global <project-name>
# remove -l "cli-builder"
# remove -b --global "cli-builder"
# remove -b "$HOME/.local/bin/cli-builder"
# reomve --search f

# local install locations
LOCAL_BIN="$HOME/.local/bin"
LOCAL_LIB="$HOME/.local/lib"

# global install locations
GLOBAL_BIN="/usr/bin"
GLOBAL_LIB="/usr/lib"

# flag to install globally
# (default: local)
GLOBAL=false

# The name of the tool that the user wants to remove.
TOOL_NAME=''

# Flag to determine if its a bin or lib
# (default: search both)
# -l | --lib will set BIN=false
# -b | --bin will set LIB=false
# if the user sets both complain and exit.
CHECK_LIB=true
CHECK_BIN=true

# Things to search for.
# Default (d) 
# f - file
# d - directory
# l - symlink
SEARCH_OPTS="d" 

RESET=$'\e[0m'
RED=$'\e[31m'
GREEN=$'\e[32m'
YELLOW=$'\e[33m'

_remove_usage() {
    cat <<EOF
Usage:
  remove [options] <project-name>

Options:
  -g, --global		Remove from global install paths
  -l, --lib		Search only lib paths
  -b, --bin		Search only bin paths
  -s, --search  <args>	What to search for (f,d,l)
  --help		Show this help message
EOF
}

_remove_error() {
    printf '%b[Error]:%b %s\n' "$RED" "$RESET" "$*" >&2
}

_remove_warn() {
    printf '%b[Warn]:%b %s\n' "$YELLOW" "$RESET" "$*" >&2
}

_remove_parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help) _remove_usage; exit 0;;
            -g|--global) GLOBAL=true; shift;;
            -l|--lib) CHECK_BIN=false; shift;;
            -b|--bin) CHECK_LIB=false; shift;;
	    -s|--search)
		[[ -n "${2:-}" ]] || { _remove_error "--search requires an argument"; exit 1; }
		SEARCH_OPTS="$2"
		shift 2
		;;
	    
            --) shift; break;;
            -*)
                _remove_error "Unknown option: $1"
                _remove_usage
                exit 1
                ;;
            *)
                if [[ -n "$TOOL_NAME" ]]; then
                    _remove_error "Too many arguments: $1"
                    _remove_usage
                    exit 1
                fi
                TOOL_NAME="$1"
                shift
                ;;
        esac
    done

    # collect anything left after --
    if [[ $# -gt 0 ]]; then
        if [[ -n "$TOOL_NAME" ]]; then
	    _remove_error "Too many arguments: $1"
            _remove_usage
            exit 1
        fi
        TOOL_NAME="$1"
        shift
    fi

    # Validate both lib and bin were not set together
    [[ "$CHECK_BIN" == false && "$CHECK_LIB" == false ]] && {
	_remove_error "No search will happen both --bin and --lib were set."
	exit 1
    }
    
    # Validate a tool name was given.
    [[ -z "$TOOL_NAME" ]] && {
	_remove_error 'missing project name'
	_remove_usage; exit 1
    }
    
}

# Check search option.
# Confirm the user passed options are
# options defined by find -type.
_check_search_opts() {
    printf "[Remove]: Validating search options %b'$SEARCH_OPTS'%b...\n" "$GREEN" "$RESET"
    echo "$SEARCH_OPTS" | \
	awk -F ',' '{
	    for(i = 1; i <= NF; i++) {
		if ($i != "f" && $i != "d" && $i != "l") {
		   printf("%c[31m[Error]:%c[0m Invalid search target %c[33m %s %c[0m\n",
		   	   0x1b, 0x1b, 0x1b, $i, 0x1b);
		   exit(1);
	       }
	    }
	    exit(0);
        }'
}

# Checks to see if the project exists
# based on the input flags check those paths
# for the project name.
_find_project_and_query_rm() {
    if [[ "$GLOBAL" == true ]]; then 	
	printf "[Remove]: Searching through the system files for $TOOL_NAME...\n"

	# Check the global bin
	[[ "$CHECK_BIN" == true && ! -d "$GLOBAL_BIN" ]] && { _remove_warn "GLOBAL_BIN does not exist."; } 
	if [[ "$CHECK_BIN" == true && -d "$GLOBAL_BIN" ]]; then
	    printf "[Remove]: Searching ${GLOBAL_BIN}...\n"
	    printf "$YELLOW[REMOVE]:$RESET answer 'yes' to files that you wish to remove.\n"
	    if find -P "$GLOBAL_BIN" -type "$SEARCH_OPTS" -name "$TOOL_NAME" \
		    -ok sh -c 'rm -r -- "$1"; [ $? -eq 0 ] && echo "removed $1"' _ {} \;
	    then
		printf "%b[Remove]:%b $GLOBAL_BIN Search finished.\n" "$GREEN" "$RESET"
	    else
		printf "%b[Remove]:%b $GLOBAL_BIN Search finished.\n" "$YELLOW" "$RESET"
	    fi
	fi
	
	# Check the global lib dir.
	[[ "$CHECK_LIB" == true && ! -d "$GLOBAL_LIB" ]] && { _remove_warn "$GLOBAL_LIB does not exist."; }
	if [[ "$CHECK_LIB" == true && -d "$GLOBAL_LIB" ]]; then
	    printf "[Remove]: Searching ${GLOBAL_LIB}...\n"
	    printf "$YELLOW[REMOVE]:$RESET answer 'yes' to files that you wish to remove.\n"
	    if find -P "$GLOBAL_LIB" -type "$SEARCH_OPTS" -name "$TOOL_NAME" \
		    -ok sh -c 'rm -r -- "$1"; [ $? -eq 0 ] && echo "removed $1"' _ {} \;
	    then
		printf "%b[Remove]:%b $GLOBAL_LIB Search finished.\n" "$GREEN" "$RESET"
	    else
		printf "%b[Remove]:%b $GLOBAL_LIB Search finished.\n" "$YELLOW" "$RESET"
	    fi
	fi
    else
	printf "[Remove]: Searching through local files for $TOOL_NAME...\n"
	
	# Check the local bin folder.
	[[ "$CHECK_BIN" == true && ! -d "$LOCAL_BIN" ]] && { _remove_warn "$LOCAL_BIN does not exist."; }
	if [[ "$CHECK_BIN" == true ]]; then
	    printf "[Remove]: Searching $LOCAL_BIN...\n"
	    printf "$YELLOW[REMOVE]:$RESET answer 'yes' to files that you wish to remove.\n"
	    if find -P "$LOCAL_BIN" -type "$SEARCH_OPTS" -name "$TOOL_NAME" -ok sh -c 'rm -r -- "$1"; [ $? -eq 0 ] && echo "removed $1"' _ {} \;
	    then
		printf "%b[Remove]:%b $LOCAL_BIN Search finished.\n" "$GREEN" "$RESET"
	    else
		printf "%b[Remove]:%b $LOCAL_BIN Search finished.\n" "$YELLOW" "$RESET"
	    fi
	fi
	
	# Check the local lib folder.
	[[ "$CHECK_LIB" == true && ! -d "$LOCAL_LIB" ]] && { _remove_warn "$LOCAL_LIB does not exist."; } 
	if [[ "$CHECK_LIB" == true && -d "$LOCAL_LIB" ]]; then
	    printf "[Remove]: Searching $LOCAL_LIB for $TOOL_NAME...\n"
	    printf "$YELLOW[REMOVE]:$RESET answer 'yes' to files that you wish to remove.\n"
	    if find -P "$LOCAL_LIB" -type "$SEARCH_OPTS" -name "$TOOL_NAME" -ok sh -c 'rm -r -- "$1"; [ $? -eq 0 ] && echo "removed $1"' _ {} \;
	    then
		printf "%b[Remove]:%b $LOCAL_LIB Search finished.\n" "$GREEN" "$RESET"
	    else
		printf "%b[Remove]:%b $LOCAL_LIB Search finished.\n" "$YELLOW" "$RESET"
	    fi
	fi
    fi
}


# removes the given project
remove_cmd() {
    _remove_parse_args "$@"

    # Validate the search targets. 
    if ! _check_search_opts; then
	exit 1
    else
	printf "[Remove]: Search target validated.\n"
    fi

    # find and remove the tool.
    # simple wrapper around find -exec/ find -ok
    _find_project_and_query_rm
    
}


