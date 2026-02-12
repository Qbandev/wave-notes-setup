#!/usr/bin/env bash
# Test helper for wave-notes-setup bats tests

# Set up test environment
setup_test_environment() {
    # Create temporary directories for testing
    local temp_dir
    temp_dir=$(mktemp -d)
    export TEST_HOME="$temp_dir"
    export HOME="$TEST_HOME"
    export TEST_WAVETERM_CONFIG="$TEST_HOME/.config/waveterm"
    export TEST_NOTES_DIR="$TEST_HOME/Documents/WaveNotes"
    export TEST_BIN_DIR="$TEST_HOME/bin"
    export TEST_CONFIG_FILE="$TEST_HOME/.wave-notes.conf"

    # Create Wave Terminal config directory (simulates installed Wave Terminal)
    mkdir -p "$TEST_WAVETERM_CONFIG"
    mkdir -p "$TEST_BIN_DIR"

    # Unset any existing environment variables that might interfere
    unset WAVE_NOTES_DIR
    unset WAVE_BIN_DIR
}

# Clean up test environment
teardown_test_environment() {
    if [[ -n "$TEST_HOME" && -d "$TEST_HOME" ]]; then
        rm -rf "$TEST_HOME"
    fi
}

# Create a mock wsh command
create_mock_wsh() {
    local mock_wsh="$TEST_BIN_DIR/wsh"
    cat > "$mock_wsh" << 'EOF'
#!/bin/bash
# Mock wsh for testing
echo "mock wsh called with: $@"
exit 0
EOF
    chmod +x "$mock_wsh"
    export PATH="$TEST_BIN_DIR:$PATH"
}

# Create a mock wsh command that supports token exchange
create_mock_wsh_with_token() {
    local mock_wsh="$TEST_BIN_DIR/wsh"
    cat > "$mock_wsh" << 'EOF'
#!/bin/bash
if [ "$1" = "token" ]; then
    echo "export WAVETERM_JWT=mock-jwt-token"
    exit 0
fi
echo "mock wsh called with: $@"
exit 0
EOF
    chmod +x "$mock_wsh"
    export PATH="$TEST_BIN_DIR:$PATH"
}

# Create a sample widgets.json with existing widgets
create_sample_widgets_json() {
    local widgets_file="$TEST_WAVETERM_CONFIG/widgets.json"
    cat > "$widgets_file" << 'EOF'
{
  "existing:widget": {
    "display:order": 1,
    "icon": "solid@star",
    "label": "Existing Widget",
    "blockdef": {
      "meta": {
        "view": "term"
      }
    }
  }
}
EOF
}

# Create a config file with custom paths
create_config_file() {
    local notes_dir="${1:-$TEST_HOME/CustomNotes}"
    local bin_dir="${2:-$TEST_HOME/CustomBin}"
    cat > "$TEST_CONFIG_FILE" << EOF
NOTES_DIR="$notes_dir"
BIN_DIR="$bin_dir"
EOF
}

# Source install.sh functions for unit testing
# This extracts functions without running main()
source_install_functions() {
    local install_script="$BATS_TEST_DIRNAME/../install.sh"

    # Source the script but prevent main from running
    # We do this by defining main as a no-op before sourcing
    eval "$(sed 's/^main "\$@"$/# main disabled for testing/' "$install_script")"
}

# Assert file contains string
assert_file_contains() {
    local file="$1"
    local expected="$2"
    if ! grep -q "$expected" "$file"; then
        echo "Expected file $file to contain: $expected"
        echo "Actual content:"
        cat "$file"
        return 1
    fi
}

# Assert file does not contain string
assert_file_not_contains() {
    local file="$1"
    local unexpected="$2"
    if grep -q "$unexpected" "$file"; then
        echo "Expected file $file NOT to contain: $unexpected"
        echo "Actual content:"
        cat "$file"
        return 1
    fi
}

# Assert JSON key exists
assert_json_has_key() {
    local file="$1"
    local key="$2"
    if command -v jq >/dev/null 2>&1; then
        if ! jq -e ".[\"$key\"]" "$file" >/dev/null 2>&1; then
            echo "Expected JSON to have key: $key"
            return 1
        fi
    else
        # Pass file and key via sys.argv to prevent command injection
        if ! python3 -c "import json, sys; d=json.load(open(sys.argv[1])); assert sys.argv[2] in d" "$file" "$key" 2>/dev/null; then
            echo "Expected JSON to have key: $key"
            return 1
        fi
    fi
}

# Assert JSON key does not exist
assert_json_not_has_key() {
    local file="$1"
    local key="$2"
    if command -v jq >/dev/null 2>&1; then
        if jq -e ".[\"$key\"]" "$file" >/dev/null 2>&1; then
            echo "Expected JSON NOT to have key: $key"
            return 1
        fi
    else
        # Pass file and key via sys.argv to prevent command injection
        # Check if key EXISTS - if so, return error
        if python3 -c "import json, sys; d=json.load(open(sys.argv[1])); assert sys.argv[2] in d" "$file" "$key" 2>/dev/null; then
            echo "Expected JSON NOT to have key: $key"
            return 1
        fi
    fi
}
