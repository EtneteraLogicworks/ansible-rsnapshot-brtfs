#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob
shopt -s dotglob


readonly SCRIPTNAME=${0##*/}
readonly USAGE="USAGE
    $SCRIPTNAME
    $SCRIPTNAME -h

DESCRIPTION
    Estimate rsnapshot backups size on btrfs file system with snapshots.

    This script estimates total backup size for each of the backup instances on
    based on total disk usage, most recent backup size and number of snapshots.

    The main goal to get an overview about disk usage of rsnapshot backup
    instances due to lack of btrfs quota support and hence unknown disk usage
    of btrfs snapshots."

BACKUP_ROOT='/mnt/data/backups'


# ------------------------------------------------------------------------------
err_message() {
    echo "$SCRIPTNAME: $1: $2" >&2
}


warning() {
    err_message 'warning' "$*"
}


error() {
    err_message 'error' "$*"
}


main() {
    [[ "$#" -eq 1 ]] && [[ "$1" == '-h' ]] && {
        echo "$USAGE"
        return 0
    }

    [[ "$#" -eq 0 ]] || {
        echo "$USAGE"
        return 1
    }

    estimate_backups
}


estimate_backups() {
    # declare global variables
    typeset -A COEFICIENTS
    typeset -A ESTIMATES
    typeset -i SUM_COEFICIENTS=0
    typeset -i TOTAL_USED_SPACE=0
    TOTAL_USED_SPACE=$(filesystem_used_space "$BACKUP_ROOT")

    count_coeficients
    count_estimates
    print_statistics
}


count_coeficients() {
    local instance coeficient

    cd "$BACKUP_ROOT"
    for instance in *; do
        coeficient=$(instance_coeficient "$instance") || continue

        COEFICIENTS[$instance]="$coeficient"
        SUM_COEFICIENTS+="$coeficient"
    done
}


count_estimates() {
    local instance size coeficient

    for instance in "${!COEFICIENTS[@]}"; do
        coeficient="${COEFICIENTS[$instance]}"
        size=$(estimate_size "$coeficient")
        ESTIMATES[$instance]="$size"
    done
}


print_statistics() {
    local instance size coeficient

    print_header
    for instance in "${!ESTIMATES[@]}"; do
        size="${ESTIMATES[$instance]}"
        coeficient="${COEFICIENTS[$instance]}"
        printline "$instance" "$coeficient" "$(size_in_gb "$size")"
    done | sort
    print_footer
}


estimate_size() {
    local coeficient="$1"
    echo "$TOTAL_USED_SPACE * $coeficient / $SUM_COEFICIENTS" \
        | bc
}


instance_coeficient() {
    local instance="$1"
    local snapshots_count snapshot_size

    snapshots_count=$(snapshots_count_for_instance "$instance")
    snapshot_size=$(snapshot_size_for_instance "$instance")

    echo $((snapshots_count*snapshot_size))
}


snapshots_count_for_instance() {
    local path="$1"

    ls -d "$path"/{hourly,daily,weekly,monthly}.* \
        | wc -l
}


snapshot_size_for_instance() {
    local path="$1"

    if ! [ -d "$path/latest" ]; then
        error "'$path' seems not to be an rsnapshot backup instance"
        return 1
    fi
    disk_usage "$path/latest"
}


filesystem_used_space() {
    local path="$1"

    df --block-size=MB "$path" \
        | awk 'NR == 2 {print $3}' \
        | strip_units
}


disk_usage() {
    local path="$1"

    du -s --block-size=MB "$path" \
        | awk '{print $1}' \
        | strip_units
}


strip_units() {
    sed 's|[kMGTPEZY]B$||'
}


size_in_gb() {
    local size="$1"
    echo $((size/1000))
}


print_header() {
    print_border
    printline 'Instance' 'Koeficient' 'Odhad [GB]'
    print_border
}


print_footer() {
    print_border
    printline 'Total' "$SUM_COEFICIENTS" "$(size_in_gb "$TOTAL_USED_SPACE")"
    print_border
}


print_border() {
    printline '' '' '' | sed 's/|/+/g; s/[^+]/-/g'
}


printline() {
    local instance="$1"
    local size="$2"
    local coeficient="$3"
    printf '| %-20s | %16s | %10s |\n' "$instance" "$size" "$coeficient"
}


# ------------------------------------------------------------------------------
main "$@"
