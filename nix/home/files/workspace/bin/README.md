# workspace/bin

This directory is for executable command links managed with `wbin`.

When adding a new command here, use `wbin` instead of creating files manually:

```sh
wbin add <target-script> [command-name]
```

If `command-name` is omitted, `wbin` uses the original target script filename.

To remove a command link:

```sh
wbin rm <command-name>
```
