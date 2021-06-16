# Role `rsnapshot_btrfs/instance`

Configure rsnapshot backup on prepared backup server with *btrfs* snapshots
support.


## Description

Configure backup instance on rsnapshot server. This role is used by *client*
role and also by *server* role to configure backups of so-called *unmanaged*
clients.

This role must run on `backup_server` or be delegated to it.


## Variables

| Variable      | Required  | Default   | Descritpion |
| ------------- | --------- | --------- | ----------- |
| backup_server | yes       |           | Inventory hostname of backup server |
| backup_target | yes       |           | Dictionary with backup parameters |

Dictionary `backup_target` has following parameters:

| Variable      | Required  | Default               | Descritpion |
| ------------- | --------- | --------------------- | ----------- |
| name          | yes       |                       | Unique identification of the backup; It should consist of `a-zA-Z0-9-_` characters only |
| hostname      | yes       |                       | Remote host to backup (ssh server) |
| user          | yes       |                       | ssh user on remote host |
| ssh_args      | no        |                       | Extra parameters for ssh connection |
| rsync_remote  | no        | sudo /usr/bin/rsync   | `rsync` command on the remote host |
| snapshots     | no        |                       | A dictionary with configured *backup levels*. Value of a backup represent how many copies of such backup is kept. Each level can be switched off by setting its value to `0` |
| .hourly       | no        | 24                    | Hourly backups |
| .daily        | no        | 7                     | Daily backups (at midnight after hourly backup) |
| .weekly       | no        | 4                     | Weekly backup (at 3 AM at Saturday after hourly backup and with `Persistent` flag) |
| .monthly      | no        | 2                     | Monthly backup (at 3 AM at Friday after first Saturday in a month after hourly backup and with `Persistent` flag) |
| files         | no        | see examples          | List of files (and directories) to backup |
| exclude       | no        | see examples          | List of excluded files (and directories) from the backup  |


## Examples

Default backup parameters:

```yaml
backup_target:
  remote_rsync: 'sudo /usr/bin/rsync'
  snapshots:
    hourly: 24
    daily: 7
    weekly: 4
    monthly: 2
  files:
    - '/boot'
    - '/etc'
    - '/var'
    - '/opt'
  exclude:
    - '/var/cache'
    - '/var/lib'
    - '/var/lib/mysql'
    - '/var/lib/postgresql'
    - '/var/run'
    - '/var/swap'
    - '/var/tmp'
```


**Calendar hint**:

There is a possibility to refer e.g. every first Sunday in a month:

```yaml
backup_target:
  snapshots:
    - name: monthly
      value: 4
      calendar: 'Sun *-*-01..07'
```
