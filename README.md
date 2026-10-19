# rex-files

My [Rex](https://www.superlogical.com/rex) configuration.

Clone it into the Rex config folder and reload:

```sh
git clone https://github.com/a10y/rex-files.git ~/.config/rex
rex config reload
```

The `cmd+r` Cargo target picker needs `fzf` and `jq` on your `PATH`.

## Live agent diffs

`bin/agent-diff-hook` opens a pane beside Claude Code that shows a live diff
of each file Claude edits. To turn it on, add these hooks to
`~/.claude/settings.json`:

```json
"hooks": {
  "PostToolUse": [
    { "matcher": "Edit|Write|MultiEdit",
      "hooks": [{ "type": "command", "command": "~/.config/rex/bin/agent-diff-hook" }] }
  ],
  "SessionEnd": [
    { "hooks": [{ "type": "command", "command": "~/.config/rex/bin/agent-diff-hook" }] }
  ]
}
```
