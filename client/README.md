# Role `rsnapshot_btrfs/client`

Role to prepare a host for remote backups from `backup_server` with `rsnapshot`
tool.


## Variables

| Variable        | Required  | Default                       | Description |
| --------------- | --------- | ----------------------------- | ----------- |
| backup_server   | yes       |                               | Inventory hostname of backup server |
|                 |           |                               |  |
| backup_target   | no        |                               | Dictionary with backup parameters; See `rsnapshot_btrfs/instance` role for details |
| .name           | no        | `inventory_hostname_short`    | Unique identification of the backup |
| .hostname       | no        | `inventory_hostname`          | Remote host to backup (ssh server) |
| .user           | no        | sshbackup                     | Backup user for remote backups (with *sudo* permission) |
| .groups         | no        | [ ssh ]                       | List of secondary groups for the user |
|                 |           |                               |  |
| backup_home_dir | no        | /var/lib/`backup_target.user` | Home directory for backup user |
