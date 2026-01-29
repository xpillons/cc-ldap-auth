#!/bin/bash
set -e
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# if CYCLECLOUD_SPEC_PATH is not set use the script directory as the base path
if [ -z "$CYCLECLOUD_SPEC_PATH" ]; then
    export CYCLECLOUD_SPEC_PATH="$script_dir/.."
fi

source "$CYCLECLOUD_SPEC_PATH/files/common.sh" 

function configure_ssh_keys() {
    cp -f "$CYCLECLOUD_SPEC_PATH"/files/init_sshkeys.sh /etc/profile.d # Copy setup script file
    chmod 644 /etc/profile.d/init_sshkeys.sh
}

# Configure SSH keys on all nodes. If users first connect to login node, scheduler or Open OnDemand node, 
# there will be no concurrent access issues.
#if ! is_compute ; then
    configure_ssh_keys
#fi
