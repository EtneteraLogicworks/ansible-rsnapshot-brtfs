#!/bin/bash
set -o nounset
set -o errexit

SCRIPTNAME=${0##*/}
USAGE="USAGE
    $SCRIPTNAME --help
    $SCRIPTNAME -al subvolume snapshot

DESCRIPTION
    Simulate \`cp -al\` for rsnapshot to use btrfs snapshot instead of
    hard links to make a backup \"snapshot\".

    This script actually creates read-only btrfs snapshot of subvolume
    \`subvolume\` named 'snapshot_YYYY-mm-dd_HH-MM-SS' and create symbolic link
    \`snapshot\` to it.

OPTIONS
    --help
            Print this help and exit

ARGUMENTS
    All arguments are required

    -al
            rsnapshot calls \`cp\` with these arguments everytime

    subvolume
            Path to a btrfs subvolume (\"mount point\")

    snapshot
            Path to a btrfs snapshot to create

EXAMPLES

    Example usage for rsnapshot
        $SCRIPTNAME -al /mnt/backup/daily.0 /mnt/backup/daily.1
"


err_print() {
    echo "$SCRIPTNAME: error: $*" >&2
}


# usage ---------------------------------------------------
[[ $# -eq 1 ]] && [[ "$1" == '--help' ]] && {
    echo "$USAGE"
    exit 0
}

[[ $# -eq 3 ]] || {
    err_print "Wrong number of arguments ($#)"
    exit 1
}

options="$1"
subvolume_link="${2%/}"
snapshot_link="${3%/}"

[[ "$options" == '-al' ]] || {
    err_print "First argument ($options) must be literal '-al'"
    exit 1
}

subvolume=$(readlink -f "$subvolume_link") || {
    err_print "Could not resolve subvolume name ($subvolume_link)"
    exit 1
}

[ -e "$snapshot_link" ] && {
    err_print "Path ($snapshot_link) already exists"
    exit 1
}

btrfs subvolume show "$subvolume" &> /dev/null || {
    err_print "Path ($subvolume) is not btrfs subvolume"
    exit 1
}


# ---------------------------------------------------------
snapshot_base_dir=$(dirname "$snapshot_link")
timestamp=$(stat --format '%Y' "$subvolume")
snapshot_name=$(date --date "@$timestamp" '+snapshot_%Y-%m-%d_%H-%M-%S')
snapshot="$snapshot_base_dir/$snapshot_name"

[ -e "$snapshot" ] && {
    err_print "Snapshot ($snapshot) already exists"
    exit 1
}

btrfs subvolume snapshot -r "$subvolume" "$snapshot" > /dev/null
ln -s "$snapshot_name" "$snapshot_link"
