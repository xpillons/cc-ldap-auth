#!/bin/bash

# Script to merge the [[[configuration]]] section from ldap_auth.txt 
# into the beginning of the [[[configuration]]] section in a template file

set -e

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Usage function
usage() {
    echo "Usage: $0 <input_template> <output_template>"
    echo ""
    echo "Arguments:"
    echo "  input_template   - Input template file (e.g., templates/slurm.txt)"
    echo "  output_template  - Output template file (e.g., templates/slurm_with_ldap.txt)"
    echo ""
    echo "Example:"
    echo "  $0 templates/slurm.txt templates/slurm_with_ldap.txt"
    exit 1
}

# Check if help is requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
fi

# File paths
LDAP_AUTH_FILE="$SCRIPT_DIR/templates/ldap_auth.txt"
SLURM_FILE="${1}"
OUTPUT_FILE="${2}"

# Validate arguments
if [ -z "$SLURM_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Error: Missing required arguments"
    echo ""
    usage
fi

# Check if files exist
if [ ! -f "$LDAP_AUTH_FILE" ]; then
    echo "Error: $LDAP_AUTH_FILE not found"
    exit 1
fi

if [ ! -f "$SLURM_FILE" ]; then
    echo "Error: $SLURM_FILE not found"
    exit 1
fi

# Extract configuration section from ldap_auth.txt
# Start after [[[configuration]]] line and stop at the [parameters section
ldap_config=$(awk '
    BEGIN { in_config = 0 }
    /^\[{3}configuration\]{3}/ { in_config = 1; next }
    in_config && /^\[parameters/ { exit }
    in_config { print }
' "$LDAP_AUTH_FILE")

# Check if we extracted anything
if [ -z "$ldap_config" ]; then
    echo "Error: No configuration section found in $LDAP_AUTH_FILE"
    exit 1
fi

# Extract parameters section from ldap_auth.txt
# Start from [parameters Authentication] to the end of file
ldap_params=$(awk '
    BEGIN { in_params = 0 }
    /^\[parameters Authentication\]/ { in_params = 1 }
    in_params { print }
' "$LDAP_AUTH_FILE")

# Create the merged file with configuration inserted
awk -v ldap_content="$ldap_config" '
    BEGIN { config_added = 0 }
    {
        print
        # After printing [[[configuration]]], add the LDAP configuration
        if (!config_added && /\[{3}configuration\]{3}/) {
            print ""
            print ldap_content
            config_added = 1
        }
    }
' "$SLURM_FILE" > "$OUTPUT_FILE.tmp"

# Append parameters section to the end of the file
if [ -n "$ldap_params" ]; then
    {
        cat "$OUTPUT_FILE.tmp"
        echo ""
        echo "$ldap_params"
    } > "$OUTPUT_FILE"
    rm "$OUTPUT_FILE.tmp"
    echo "Successfully merged LDAP configuration and parameters from $LDAP_AUTH_FILE into $OUTPUT_FILE"
    echo "- Configuration added at the beginning of the [[[configuration]]] section"
    echo "- Parameters section appended at the end of the file"
else
    mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
    echo "Successfully merged LDAP configuration from $LDAP_AUTH_FILE into $OUTPUT_FILE"
    echo "The LDAP configuration has been added at the beginning of the [[[configuration]]] section"
    echo "Warning: No parameters section found to append"
fi
