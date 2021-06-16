#!/bin/bash
set -o nounset
set -o errexit

SCRIPTNAME=${0##*/}
USAGE="USAGE
    $SCRIPTNAME --help
    $SCRIPTNAME -rf snapshot

DESCRIPTION
    Simulate \`rm -rf\` for rsnapshot to remove btrfs snapshot instead of
    recursively remove of a directory.

    This script actually removes btrfs snapshot \`snapshot\` (or in case of
    symbolic link, a snapshot link points to and the link itself).

OPTIONS
    --help
            Print this help and exit

ARGUMENTS
    All arguments are required

    -rf
            rsnapshot calls \`rm\` with these arguments everytime

    snapshot
            Path (or symbolic link) to a btrfs snapshot to remove

EXAMPLES

    Example usage for rsnapshot
        $SCRIPTNAME -rf /mnt/backup/daily.6
"


err_print() {
    echo "$SCRIPTNAME: error: $*" >&2
}


# usage ---------------------------------------------------
[[ $# -eq 1 ]] && [[ "$1" == '--help' ]] && {
    echo "$USAGE"
    exit 0
}

[[ $# -eq 2 ]] || {
    err_print "Wrong number of arguments ($#)"
    exit 1
}

options="$1"
snapshot_link="${2%/}"

[[ "$options" == '-rf' ]] || {
    err_print "First argument ($options) must be literal '-rf'"
    exit 1
}

snapshot=$(readlink -f "$snapshot_link") || {
    err_print "Could not resolve subvolume name ($snapshot_link)"
    exit 1
}

# check btrfs snapshot
info=$(btrfs subvolume show "$snapshot" 2> /dev/null) || {
    err_print "Path ($snapshot) is not a btrfs subvolume"
    exit 1
}

puuid=$(gawk -F '\\t+|:\\s+' '$2 == "Parent UUID" {print $3}'<<<"$info")
[[ "$puuid" =~ ^[[:xdigit:]]{8}-([[:xdigit:]]{4}-){3}[[:xdigit:]]{12}$ ]] || {
    err_print "Path ($snapshot) does not appear as a snapshot"
    exit 1
}


# ---------------------------------------------------------
btrfs subvolume delete "$snapshot" > /dev/null
if [ -L "$snapshot_link" ]; then
    rm "$snapshot_link"
fi
