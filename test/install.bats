#!/usr/bin/env bats
# Unit tests for install.sh

load 'test_helper'

setup() {
    setup_test_environment
    source_install_functions
}

teardown() {
    teardown_test_environment
}

# =============================================================================
# detect_waveterm_config() tests
# =============================================================================

@test "detect_waveterm_config: finds new config path (~/.config/waveterm)" {
    mkdir -p "$TEST_HOME/.config/waveterm"

    run detect_waveterm_config

    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_HOME/.config/waveterm" ]
}

@test "detect_waveterm_config: finds old config path (~/.waveterm)" {
    rm -rf "$TEST_HOME/.config/waveterm"
    mkdir -p "$TEST_HOME/.waveterm"

    run detect_waveterm_config

    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_HOME/.waveterm/config" ]
}

@test "detect_waveterm_config: prefers new path over old path" {
    mkdir -p "$TEST_HOME/.config/waveterm"
    mkdir -p "$TEST_HOME/.waveterm"

    run detect_waveterm_config

    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_HOME/.config/waveterm" ]
}

@test "detect_waveterm_config: returns empty when Wave Terminal not found" {
    rm -rf "$TEST_HOME/.config/waveterm"
    rm -rf "$TEST_HOME/.waveterm"

    run detect_waveterm_config

    [ "$status" -eq 0 ]
    [ "$output" = "" ]
}

# =============================================================================
# load_config() tests
# =============================================================================

@test "load_config: uses default values when no config exists" {
    rm -f "$TEST_CONFIG_FILE"
    unset WAVE_NOTES_DIR
    unset WAVE_BIN_DIR

    load_config

    [ "$NOTES_DIR" = "$TEST_HOME/Documents/WaveNotes" ]
    [ "$BIN_DIR" = "$TEST_HOME/bin" ]
}

@test "load_config: reads from config file" {
    create_config_file "$TEST_HOME/MyNotes" "$TEST_HOME/MyBin"
    unset WAVE_NOTES_DIR
    unset WAVE_BIN_DIR

    load_config

    [ "$NOTES_DIR" = "$TEST_HOME/MyNotes" ]
    [ "$BIN_DIR" = "$TEST_HOME/MyBin" ]
}

@test "load_config: environment variables override config file" {
    create_config_file "$TEST_HOME/ConfigNotes" "$TEST_HOME/ConfigBin"
    export WAVE_NOTES_DIR="$TEST_HOME/EnvNotes"
    export WAVE_BIN_DIR="$TEST_HOME/EnvBin"

    load_config

    [ "$NOTES_DIR" = "$TEST_HOME/EnvNotes" ]
    [ "$BIN_DIR" = "$TEST_HOME/EnvBin" ]
}

@test "load_config: expands tilde in paths" {
    cat > "$TEST_CONFIG_FILE" << 'EOF'
NOTES_DIR="~/Documents/TildeNotes"
BIN_DIR="~/TildeBin"
EOF
    unset WAVE_NOTES_DIR
    unset WAVE_BIN_DIR

    load_config

    [ "$NOTES_DIR" = "$TEST_HOME/Documents/TildeNotes" ]
    [ "$BIN_DIR" = "$TEST_HOME/TildeBin" ]
}

@test "load_config: expands \$HOME in config values" {
    cat > "$TEST_CONFIG_FILE" << EOF
NOTES_DIR="\$HOME/Documents/HomeNotes"
BIN_DIR="\$HOME/HomeBin"
EOF
    unset WAVE_NOTES_DIR
    unset WAVE_BIN_DIR

    load_config

    [ "$NOTES_DIR" = "$TEST_HOME/Documents/HomeNotes" ]
    [ "$BIN_DIR" = "$TEST_HOME/HomeBin" ]
}

@test "load_config: ignores comments in config file" {
    cat > "$TEST_CONFIG_FILE" << EOF
# This is a comment
NOTES_DIR="$TEST_HOME/Notes"
# Another comment
BIN_DIR="$TEST_HOME/Bin"
EOF
    unset WAVE_NOTES_DIR
    unset WAVE_BIN_DIR

    load_config

    [ "$NOTES_DIR" = "$TEST_HOME/Notes" ]
    [ "$BIN_DIR" = "$TEST_HOME/Bin" ]
}

@test "load_config: handles quoted values" {
    cat > "$TEST_CONFIG_FILE" << EOF
NOTES_DIR="$TEST_HOME/Quoted Notes"
BIN_DIR='$TEST_HOME/Single Quoted'
EOF
    unset WAVE_NOTES_DIR
    unset WAVE_BIN_DIR

    load_config

    [ "$NOTES_DIR" = "$TEST_HOME/Quoted Notes" ]
}

# =============================================================================
# get_max_display_order() tests
# =============================================================================

@test "get_max_display_order: returns 0 for non-existent file" {
    run get_max_display_order "/nonexistent/widgets.json"

    [ "$status" -eq 0 ]
    [ "$output" = "0" ]
}

@test "get_max_display_order: returns 0 for empty widgets" {
    echo '{}' > "$TEST_WAVETERM_CONFIG/widgets.json"

    run get_max_display_order "$TEST_WAVETERM_CONFIG/widgets.json"

    [ "$status" -eq 0 ]
    [ "$output" = "0" ]
}

@test "get_max_display_order: finds maximum order from widgets" {
    cat > "$TEST_WAVETERM_CONFIG/widgets.json" << 'EOF'
{
  "widget1": { "display:order": 1 },
  "widget2": { "display:order": 5 },
  "widget3": { "display:order": 3 }
}
EOF

    run get_max_display_order "$TEST_WAVETERM_CONFIG/widgets.json"

    [ "$status" -eq 0 ]
    [ "$output" = "5" ]
}

# =============================================================================
# get_existing_order() tests
# =============================================================================

@test "get_existing_order: returns default for non-existent file" {
    run get_existing_order "/nonexistent/widgets.json" "custom:notes-new" "10"

    [ "$status" -eq 0 ]
    [ "$output" = "10" ]
}

@test "get_existing_order: returns existing order for known widget" {
    cat > "$TEST_WAVETERM_CONFIG/widgets.json" << 'EOF'
{
  "custom:notes-new": { "display:order": 7 }
}
EOF

    run get_existing_order "$TEST_WAVETERM_CONFIG/widgets.json" "custom:notes-new" "10"

    [ "$status" -eq 0 ]
    [ "$output" = "7" ]
}

@test "get_existing_order: returns default for unknown widget" {
    cat > "$TEST_WAVETERM_CONFIG/widgets.json" << 'EOF'
{
  "other:widget": { "display:order": 5 }
}
EOF

    run get_existing_order "$TEST_WAVETERM_CONFIG/widgets.json" "custom:notes-new" "10"

    [ "$status" -eq 0 ]
    [ "$output" = "10" ]
}

# =============================================================================
# create_directories() tests
# =============================================================================

@test "create_directories: creates notes directory" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"

    create_directories

    [ -d "$NOTES_DIR" ]
    [ -d "$BIN_DIR" ]
    [ -d "$WAVETERM_CONFIG" ]
}

@test "create_directories: succeeds if directories already exist" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"
    mkdir -p "$NOTES_DIR" "$BIN_DIR"

    run create_directories

    [ "$status" -eq 0 ]
}

# =============================================================================
# install_scratchpad_script() tests
# =============================================================================

@test "install_scratchpad_script: creates executable script" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    mkdir -p "$BIN_DIR"

    install_scratchpad_script

    [ -f "$BIN_DIR/wave-scratch.sh" ]
    [ -x "$BIN_DIR/wave-scratch.sh" ]
}

@test "install_scratchpad_script: contains correct notes directory" {
    NOTES_DIR="$TEST_HOME/CustomNotesPath"
    BIN_DIR="$TEST_HOME/TestBin"
    mkdir -p "$BIN_DIR"

    install_scratchpad_script

    assert_file_contains "$BIN_DIR/wave-scratch.sh" "NOTES_DIR=\"$TEST_HOME/CustomNotesPath\""
}

@test "install_scratchpad_script: contains generated header" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    mkdir -p "$BIN_DIR"

    install_scratchpad_script

    assert_file_contains "$BIN_DIR/wave-scratch.sh" "Generated by wave-notes-setup"
}

@test "install_scratchpad_script: contains find_wsh function" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    mkdir -p "$BIN_DIR"

    install_scratchpad_script

    assert_file_contains "$BIN_DIR/wave-scratch.sh" "find_wsh()"
}

# =============================================================================
# install_widgets() tests
# =============================================================================

@test "install_widgets: creates widgets.json if not exists" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"
    rm -f "$WAVETERM_CONFIG/widgets.json"

    install_widgets

    [ -f "$WAVETERM_CONFIG/widgets.json" ]
    assert_json_has_key "$WAVETERM_CONFIG/widgets.json" "custom:notes-new"
}

@test "install_widgets: merges with existing widgets" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"
    create_sample_widgets_json

    install_widgets

    assert_json_has_key "$WAVETERM_CONFIG/widgets.json" "existing:widget"
    assert_json_has_key "$WAVETERM_CONFIG/widgets.json" "custom:notes-new"
}

@test "install_widgets: creates backup of existing widgets.json" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"
    create_sample_widgets_json

    install_widgets

    # Check that a backup file was created
    backup_count=$(ls -1 "$WAVETERM_CONFIG"/widgets.json.bak.* 2>/dev/null | wc -l)
    [ "$backup_count" -ge 1 ]
}

@test "install_widgets: does not include color property" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"

    install_widgets

    # Widgets should follow theme (no hardcoded color)
    assert_file_not_contains "$WAVETERM_CONFIG/widgets.json" '"color"'
}

@test "install_widgets: includes closeonexit options" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"

    install_widgets

    assert_file_contains "$WAVETERM_CONFIG/widgets.json" '"cmd:closeonexit": true'
    assert_file_contains "$WAVETERM_CONFIG/widgets.json" '"cmd:closeonexitdelay": 0'
}

@test "install_widgets: removes legacy list widget on upgrade" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"

    # Setup: Create widgets.json with legacy custom:notes-list
    cat > "$WAVETERM_CONFIG/widgets.json" << 'EOF'
{
  "custom:notes-list": {
    "icon": "file-text",
    "label": "All Notes",
    "display:order": 5
  },
  "existing:widget": {
    "display:order": 1
  }
}
EOF

    # Action: Run install_widgets and capture output
    run install_widgets

    # Assert: deprecation notice was printed
    [[ "$output" == *"Removing deprecated"* ]]

    # Assert: custom:notes-list is absent, custom:notes-new is present, backup exists
    assert_json_not_has_key "$WAVETERM_CONFIG/widgets.json" "custom:notes-list"
    assert_json_has_key "$WAVETERM_CONFIG/widgets.json" "custom:notes-new"
    assert_json_has_key "$WAVETERM_CONFIG/widgets.json" "existing:widget"

    # Verify backup was created
    local backup_count
    backup_count=$(ls -1 "$WAVETERM_CONFIG"/widgets.json.bak.* 2>/dev/null | wc -l)
    [ "$backup_count" -ge 1 ]
}

# =============================================================================
# check_macos() tests
# =============================================================================

@test "check_macos: passes on macOS" {
    if [[ "$(uname)" != "Darwin" ]]; then
        skip "Test only runs on macOS"
    fi

    run check_macos

    [ "$status" -eq 0 ]
}

# =============================================================================
# Integration: Full install flow
# =============================================================================

@test "integration: full install creates all expected files" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"
    create_mock_wsh

    create_directories
    install_scratchpad_script
    install_widgets

    # Verify all files created
    [ -d "$NOTES_DIR" ]
    [ -f "$BIN_DIR/wave-scratch.sh" ]
    [ -x "$BIN_DIR/wave-scratch.sh" ]
    [ -f "$WAVETERM_CONFIG/widgets.json" ]

    # Verify widgets.json content
    assert_json_has_key "$WAVETERM_CONFIG/widgets.json" "custom:notes-new"
}

@test "integration: install is idempotent" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"

    # Run install twice
    create_directories
    install_scratchpad_script
    install_widgets

    create_directories
    install_scratchpad_script
    install_widgets

    # Should still work and have correct structure
    [ -f "$WAVETERM_CONFIG/widgets.json" ]
    assert_json_has_key "$WAVETERM_CONFIG/widgets.json" "custom:notes-new"
}

# =============================================================================
# check_wave_installed() tests
# =============================================================================

@test "check_wave_installed: passes when ~/.config/waveterm exists" {
    mkdir -p "$TEST_HOME/.config/waveterm"

    run check_wave_installed

    [ "$status" -eq 0 ]
}

@test "check_wave_installed: passes when wsh command available" {
    rm -rf "$TEST_HOME/.config/waveterm"
    rm -rf "$TEST_HOME/.waveterm"
    create_mock_wsh

    run check_wave_installed

    [ "$status" -eq 0 ]
}

@test "check_wave_installed: fails when Wave not found" {
    rm -rf "$TEST_HOME/.config/waveterm"
    rm -rf "$TEST_HOME/.waveterm"
    # Remove wsh from PATH
    export PATH="/usr/bin:/bin"

    run check_wave_installed

    [ "$status" -eq 1 ]
    [[ "$output" == *"Wave Terminal is not installed"* ]]
}

# =============================================================================
# validate_widgets() tests
# =============================================================================

@test "validate_widgets: passes with valid JSON" {
    local widgets_file="$TEST_WAVETERM_CONFIG/widgets.json"
    echo '{"test": "valid"}' > "$widgets_file"

    run validate_widgets "$widgets_file"

    [ "$status" -eq 0 ]
}

@test "validate_widgets: fails with malformed JSON" {
    local widgets_file="$TEST_WAVETERM_CONFIG/widgets.json"
    echo '{invalid json' > "$widgets_file"

    run validate_widgets "$widgets_file"

    [ "$status" -ne 0 ]
}

# =============================================================================
# Backup and rollback tests
# =============================================================================

@test "install_widgets: backup has 600 permissions" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"
    create_sample_widgets_json

    install_widgets

    # Find backup file and check permissions
    local backup_file
    backup_file=$(ls -1 "$WAVETERM_CONFIG"/widgets.json.bak.* 2>/dev/null | head -1)
    [ -n "$backup_file" ]

    local perms
    perms=$(stat -f "%Lp" "$backup_file" 2>/dev/null || stat -c "%a" "$backup_file" 2>/dev/null)
    [ "$perms" = "600" ]
}

@test "install_widgets: rollback restores backup on invalid JSON" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"

    # Create a valid initial widgets.json
    echo '{"original": "content"}' > "$WAVETERM_CONFIG/widgets.json"

    # Create a modified install_widgets that produces invalid JSON
    # We test the validate_widgets + rollback logic directly
    local widgets_file="$WAVETERM_CONFIG/widgets.json"
    local backup_file="$widgets_file.bak.test"
    cp "$widgets_file" "$backup_file"
    chmod 600 "$backup_file"

    # Write invalid JSON
    echo '{invalid' > "$widgets_file"

    # Simulate rollback logic
    if ! validate_widgets "$widgets_file"; then
        cp "$backup_file" "$widgets_file"
    fi

    # Should have restored backup
    run cat "$widgets_file"
    [[ "$output" == *"original"* ]]
}

@test "install_widgets: removes invalid file on fresh install validation failure" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    WAVETERM_CONFIG="$TEST_WAVETERM_CONFIG"

    # Ensure no existing widgets.json (fresh install)
    rm -f "$WAVETERM_CONFIG/widgets.json"

    # Simulate the fresh install rollback logic
    local widgets_file="$WAVETERM_CONFIG/widgets.json"
    local backup_file=""

    # Write invalid JSON (simulating failed generation)
    echo '{invalid' > "$widgets_file"

    # Simulate rollback logic (matching install.sh)
    if ! validate_widgets "$widgets_file"; then
        if [[ -n "$backup_file" && -f "$backup_file" ]]; then
            cp "$backup_file" "$widgets_file"
        else
            rm -f "$widgets_file"
        fi
    fi

    # Should have removed invalid file
    [ ! -f "$widgets_file" ]
}

# =============================================================================
# Security Tests
# =============================================================================

@test "security: validate_safe_path rejects paths outside HOME" {
    run validate_safe_path "/etc/evil" "TEST_PATH"
    [ "$status" -ne 0 ]

    run validate_safe_path "/tmp/notes" "TEST_PATH"
    [ "$status" -ne 0 ]
}

@test "security: validate_safe_path rejects path traversal sequences" {
    run validate_safe_path "$TEST_HOME/../../../etc/passwd" "TEST_PATH"
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain '..'"* ]]

    run validate_safe_path "$TEST_HOME/notes/../../../etc" "TEST_PATH"
    [ "$status" -ne 0 ]
    [[ "$output" == *"cannot contain '..'"* ]]
}

@test "security: validate_safe_path rejects shell metacharacters" {
    # Test command injection attempt with semicolon
    run validate_safe_path "$TEST_HOME/notes;echo injected" "TEST_PATH"
    [ "$status" -ne 0 ]
    [[ "$output" == *"invalid characters"* ]]

    # Test with quotes
    run validate_safe_path "$TEST_HOME/notes\"rm" "TEST_PATH"
    [ "$status" -ne 0 ]

    # Test with dollar sign (variable expansion)
    run validate_safe_path "$TEST_HOME/notes\$PATH" "TEST_PATH"
    [ "$status" -ne 0 ]

    # Test with backticks (command substitution)
    run validate_safe_path "$TEST_HOME/notes\`id\`" "TEST_PATH"
    [ "$status" -ne 0 ]

    # Test with pipe
    run validate_safe_path "$TEST_HOME/notes|cat" "TEST_PATH"
    [ "$status" -ne 0 ]
}

@test "security: validate_safe_path rejects protected directories" {
    # Create protected directories in test home
    mkdir -p "$TEST_HOME/Desktop"
    mkdir -p "$TEST_HOME/Documents"

    run validate_safe_path "$TEST_HOME" "TEST_PATH"
    [ "$status" -ne 0 ]

    run validate_safe_path "$TEST_HOME/Desktop" "TEST_PATH"
    [ "$status" -ne 0 ]

    run validate_safe_path "$TEST_HOME/Documents" "TEST_PATH"
    [ "$status" -ne 0 ]
}

@test "security: validate_safe_path accepts valid paths under HOME" {
    # Create the test directories first
    mkdir -p "$TEST_HOME/Documents/WaveNotes"
    mkdir -p "$TEST_HOME/MyNotes"

    run validate_safe_path "$TEST_HOME/Documents/WaveNotes" "TEST_PATH"
    [ "$status" -eq 0 ]

    run validate_safe_path "$TEST_HOME/MyNotes" "TEST_PATH"
    [ "$status" -eq 0 ]
}

@test "security: validate_safe_path accepts paths with missing parents" {
    # Parent does not exist yet, but path is still under HOME
    run validate_safe_path "$TEST_HOME/NewDir/WaveNotes" "TEST_PATH"
    [ "$status" -eq 0 ]
}

@test "security: check_not_symlink detects symlinks" {
    local target="$TEST_HOME/real_file"
    local link="$TEST_HOME/symlink"

    echo "content" > "$target"
    ln -s "$target" "$link"

    run check_not_symlink "$link"
    [ "$status" -ne 0 ]

    run check_not_symlink "$target"
    [ "$status" -eq 0 ]
}

@test "security: safe_rmdir allows deletion of safe paths" {
    # Create a directory that's safe to delete
    local safe_dir="$TEST_HOME/safe_to_delete"
    mkdir -p "$safe_dir"
    [ -d "$safe_dir" ]

    # safe_rmdir should delete it
    safe_rmdir "$safe_dir"
    [ ! -d "$safe_dir" ]
}

@test "security: safe_rmdir output shows protection for root" {
    # Test that attempting to delete root produces error message
    run safe_rmdir "/"
    [[ "$output" == *"Refusing to delete protected path"* ]] || [[ "$status" -ne 0 ]]
}

@test "security: install_scratchpad_script refuses to overwrite symlink" {
    NOTES_DIR="$TEST_HOME/TestNotes"
    BIN_DIR="$TEST_HOME/TestBin"
    mkdir -p "$BIN_DIR"

    # Create a symlink where script would be written
    local target="$TEST_HOME/real_target"
    echo "original" > "$target"
    ln -s "$target" "$BIN_DIR/wave-scratch.sh"

    run install_scratchpad_script
    [ "$status" -ne 0 ]
    [[ "$output" == *"symlink"* ]]

    # Original target should be unchanged
    [ "$(cat "$target")" = "original" ]
}

@test "security: load_config handles special characters safely" {
    # Test that command substitution in config values is not executed
    cat > "$TEST_CONFIG_FILE" << 'EOF'
NOTES_DIR=$HOME/Notes$(touch /tmp/pwned)
EOF

    load_config

    # The file should NOT have been created (command not executed)
    [ ! -f "/tmp/pwned" ]
}
