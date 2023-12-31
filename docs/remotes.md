# Remotes

Manage a set of references to 3scale accounts (on the same or different instances).

Added remotes are stored in configuration file and can be used in any command where 3scale instances need to be specified.

## Synopsis

```
3scale remote [--config-file <config_file>]
3scale remote list [--config-file <config_file>]
3scale remote add [--config-file <config_file>] <name> <url>
3scale remote remove [--config-file <config_file>] <name>
3scale remote rename [--config-file <config_file>] <old_name> <new_name>
```

## Options

*--config-file <config_file>*

3scale toolbox configuration file. When not set, the toolbox will use either:

* path specified in the *THREESCALE_CLI_CONFIG* environment variable
* the default of `$HOME/.3scalerc.yaml` when not specified by --config-file option or environment variable

## Remote URLS

The 3scale toolbox accesses 3scale instances using a `HTTP[S]` URL.
Tokens are used for authentication and authorization purposes.
It is encouraged to use 3scale account personal `Access Tokens`
and the use of the tenant `Provider Key` is discouraged.

The following syntax is used:

```
http[s]://<access_token>@<3scale-instance-domain>
```

## Commands
Several subcommands are available to perform operations on the remotes.

### List

Shows the list of existing remotes (name, URL and authentication key).

Example:

```shell
$ 3scale remote list
instance_a https://example_a.net 123456789
instance_b https://example_b.net 987654321
```

### Add

Adds a remote named <name> for the 3scale instance at `<url>`.

Example:

```shell
3scale remote add instance_a https://123456789@example_a.net
```

### Remove

Remove the remote named `<name>`.

Example:

```shell
3scale remote remove instance_a
```

### Rename

Rename the remote named `<old>` to `<new>`.

Example:

```shell
3scale remote rename instance_a instance_b
```
