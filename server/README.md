# Role `rsnapshot_btrfs/server`

Role to prepare a server for backups with `rsnapshot` tool with snapshots via
*btrfs subvolumes* and *snapshots*.


## Statistics

Each month, a statistics report with estimated sizes of each of backup instance
is generated and send to specified list of e-mail addresses.


## Variables

| Variable                    | Required  | Default         | Description |
| --------------------------- | --------- | --------------- | ----------- |
| rsnapshot_backup_dir        | yes       |                 | Root directory for backups; It must be on *btrfs* file system |
|               |             |           |                 |
| rsnapshot_statistics_from   | no        | `admin_mail`    | Sender address for statistics report e-mail |
| rsnapshot_statistics_to     | no        | [`admin_mail`,] | List of recipients e-mail addresses for statistics report |
|                             |           |                 |  |
| rsnapshot_unmanaged_backups | no        |                 | List of backups of hosts not managed via Ansible; See `rsnapshot_btrfs/instance` role for details |
