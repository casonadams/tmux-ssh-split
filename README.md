# tmux-ssh-split

This plugin lets tmux split in an ssh session, invoking the new pane to start
another ssh session on the same machine.

Should work with `ssh` and `mosh` connections.

## Example setup

- Install tmp plugins with `prefix I`
- Update tmp plugins with `prefix U`

```conf
if "test ! -d ~/.tmux/plugins/tpm" \
   "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins'"

set -g @plugin 'casonadams/tmux-ssh-split'

# other tmp plugins
# ...

run -b '~/.tmux/plugins/tpm/tpm'
```

- **NOTE** put this at the end of your `~/.tmux.conf` file.

## Hard coded bind-keys

tmux-ssh-split isn't very configurable yet.

| command    | description      |
| ---------- | ---------------- |
| prefix '%' | split horizontal |
| prefix '"' | split vertical   |
