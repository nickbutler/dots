Nick Butler's Dotfiles
======================

Configuration for [fish][1], [tmux][2], [Neovim][3], [Ghostty][4], and more.

[1]: https://fishshell.com
[2]: https://github.com/tmux/tmux
[3]: https://neovim.io/
[4]: https://ghostty.org

---

## Setup

**New machine:**

```sh
git clone https://github.com/nickbutler/dotfiles.git ~/.config/dotfiles
~/.config/dotfiles/bin/dots
```

Checks for required programs, symlinks configs and bin scripts, and prompts for optional extras. After that `dots` is on your `$PATH`.

**Updates** — run `dots` at any time to check for new commits and apply them:

```
$ dots
3 new commits on master:
  abc1234 Fish: Add new abbreviation
  def5678 Nvim: Update LSP config
  ghi9012 Tmux: Tweak status line

Pull updates? [y/N]
```

Pulling re-runs the link steps automatically so any new configs or scripts are wired up.

---

## Fish

**Auto-start tmux** — interactive shells outside tmux attach to (or create) a `main` session automatically. SSH sessions skip this.

**Smart window launch** — when a new tmux window is created, fish runs its name as a command or jumps to the matching directory via `z`.

**Key bindings** (inside tmux):

| Key | Action |
|-----|--------|
| `Ctrl+T` | fzf file picker |
| `Ctrl+R` | fzf history search |
| `Ctrl+C` / `Tab` | fzf directory jump (uses `z` frecency) |
| `Alt+K` / `Alt+J` | history token search backward/forward |
| `Ctrl+X Ctrl+E` | edit current command in `$EDITOR` |

**Abbreviations** — common shortcuts including `v`/`nvim`, `g`/`git`, `s`/`git status`, `gl` (graph log), `r`/`ranger`, `t`/`tig --all`, `pw` (generate password).

**Notable functions:**

| Function | Description |
|----------|-------------|
| `n [init]` | Per-project notes file (`.notes.md`), walks up to find it; `init` creates one |
| `mux <cmd> <var1,var2,...>` | Run a command against multiple args in a tiled tmux layout with panes synced |
| `tmuxnew` | fzf-style tmux window picker based on `z` history |
| `tmuxpasskey` | Toggle key pass-through to vim/fzf vs tmux (used for shared `C-j/k/l` bindings) |
| `biome` | Per-directory environment loader — sources a `.biome` file on `cd`, restores on exit; masks secrets in `list` output |
| `z` | Frecency-based directory jumping |
| `mkcd` | `mkdir -p` + `cd` |
| `pssh <proxy> <opts>` | SSH via a proxy host |
| `ai` | Quick Claude Haiku query from the shell |
| `dots` | Check for dotfile updates, show commits, prompt to pull and re-link |
| `reload` | Restart fish shell (`exec fish`) |

---

## Tmux

**Theme:** Nordfox, with active pane background lighter than inactive panes.

**Prefix:** `C-Space`

**Pane navigation** — shared with Neovim via `tmuxpasskey`:

| Key | Action |
|-----|--------|
| `C-j / C-k / C-l` | Move between panes (or Neovim splits) |
| `C-z` | Zoom/unzoom current pane |
| `h/j/k/l` (with prefix) | Resize pane (small) |
| `H/J/K/L` (with prefix) | Resize pane (large) |
| `F1–F5` | Select pane 1–5 |

**Window management:**

| Key | Action |
|-----|--------|
| `Alt+N` | New window (tmuxnew picker) |
| `Alt+R` | Rename window |
| `Alt+1–5` | Go to window 1–5 |
| `F10` | `choose-tree` session/window switcher |
| `s` (with prefix) | Split horizontal |
| `v` (with prefix) | Split vertical, main-vertical layout |
| `Space` (with prefix) | Reset to main-vertical layout |

**Copy mode** (vi keys):

| Key | Action |
|-----|--------|
| `C-q` | Enter copy mode |
| `C-[` | Enter copy mode |
| `/` (with prefix) | Search in copy mode |
| `Enter` / `MouseDragEnd` | Copy selection to system clipboard |
| `K/J` | Select line up/down |
| `.` (with prefix) | Copy previous line and paste |

---

## Neovim

**Plugin manager:** `vim.pack` (Neovim native, 0.11+). Update with `:Install`.

**Theme:** Nordfox with transparent background (inherits pane background from tmux).

**Leader:** `Space`

### Navigation

| Key | Action |
|-----|--------|
| `C-f` | fzf file picker |
| `C-s` | fzf ripgrep search |
| `C-b` | fzf buffer picker |
| `C-h` | fzf recent file history |
| `C-g` | tig (git browser) |
| `C-j/k/l` | Move between splits / tmux panes |
| `Tab` | Alternate buffer |
| `C-n / C-p` | Next/previous buffer (barbar) |
| `1–5 Tab` | Jump to buffer 1–5 |
| `F6` | Symbols outline |

### Editing

| Key | Action |
|-----|--------|
| `S` | Start global substitution `:%s::` |
| `C-_` | Toggle comment (line) |
| `C-\` | Toggle comment (paragraph) |
| `Leader+q` | Reflow paragraph |
| `Leader+w` | Strip trailing whitespace |
| `Leader+p/P` | Paste from system clipboard |
| `Leader+y` (visual) | Yank to system clipboard |
| `Enter` (visual) | Yank to system clipboard + trim |

### Git (gitsigns + fugitive)

| Key | Action |
|-----|--------|
| `gs / gr` | Stage / reset hunk |
| `go` | Preview hunk |
| `]c / [c` | Next/previous hunk |
| `Leader+gd/gD` | Diff this / against HEAD~ |
| `C-g` | Open tig |
| `Leader+g` | `:Git` command prompt |

### Commands

| Command | Description |
|---------|-------------|
| `:Reload` | Re-source `init.lua` |
| `:Install` | Reload + update plugins |
| `:PwdHistory` | fzf history scoped to current directory |
| `:Password [n]` | Generate a password with `pwgen` |
| `:TabFix` | Convert tabs to spaces |
| `:Copy` | Trim whitespace from clipboard register |

### Alt-key mappings

`Cmd+a/b/c/f/j/k/n/p/r/w` send the corresponding `Esc+<key>` sequence, enabling readline-style word movements and other alt-bindings in the terminal.

### Plugins

| Plugin | Purpose |
|--------|---------|
| barbar | Buffer tabs |
| fzf / fzf.vim | Fuzzy finding |
| gitsigns | Inline git hunks |
| vim-fugitive | Git commands |
| vim-tig | tig integration |
| vim-ranger | ranger file manager |
| lualine | Status line |
| nightfox | Colour scheme |
| vim-surround / vim-abolish | Text objects |
| vim-commentary | Commenting |
| vim-table-mode | Markdown table formatting |
| symbols-outline | Code symbol tree |
| vim-dadbod | Database client |
| auto-pairs | Bracket completion |
| vim-tmux-navigator | Shared pane navigation |
