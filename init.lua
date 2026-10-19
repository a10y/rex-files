-- Move Toggle Sidebar from its default (cmd+/) to cmd+b
rex.unbind("cmd+/", "client.sidebar.toggle")
rex.bind("cmd+b", "client.sidebar.toggle")

-- cmd+r: in a Cargo project, open a pane that lists bin and bench targets
-- and runs the one you pick. Elsewhere, cmd+r goes to the terminal as usual.
local TERMINAL = "com.superlogical.terminal"
local CARGO_TARGETS = os.getenv("HOME") .. "/.config/rex/bin/cargo-targets"

-- The working directory of a terminal block, or nil if it isn't a terminal.
local function block_cwd(block_id)
  local p = rex.block.call(TERMINAL, "process", { block_id = block_id })
  if p and p.foreground and p.foreground.cwd then
    return p.foreground.cwd
  end
  local r = rex.block.call(TERMINAL, "pwd", { block_id = block_id })
  if r and r.pwd then
    local path = r.pwd:gsub("^file://[^/]*", "")
    return (path:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
  end
end

-- The nearest directory at or above dir that has a Cargo.toml, or nil.
local function cargo_root(dir)
  while dir and dir ~= "" do
    local f = io.open(dir .. "/Cargo.toml")
    if f then
      f:close()
      return dir
    end
    if dir == "/" then return nil end
    dir = dir:match("^(.*)/[^/]*$")
    if dir == "" then dir = "/" end
  end
end

-- Open the target picker beside block_id. Returns false if dir isn't in a Cargo project.
local function open_cargo_targets(block_id, dir)
  local root = cargo_root(dir)
  if not root then return false end
  local _, err = rex.session.new_split{
    anchor_block_id = block_id,
    direction = "vertical",
    side = "after",
    focus = true,
    layout = rex.layout.block{
      flavor = TERMINAL .. ".shell",
      options = { command = { CARGO_TARGETS }, cwd = root },
    },
  }
  if err ~= nil then error(err, 0) end
  return true
end

rex.action{
  name = "cargo_targets",
  title = "Run Cargo Target…",
  description = "Pick a bin or bench target in the current Cargo project and run it in a new pane.",
  keywords = "rust cargo bench run build",
  args = { dir = "string?" },
  run = function(ctx, args)
    local dir = args.dir or block_cwd(ctx.block_id)
    if not open_cargo_targets(ctx.block_id, dir) then
      error("not in a Cargo project: " .. tostring(dir), 0)
    end
  end,
}

rex.bind("cmd+r", function(ctx, ev)
  return open_cargo_targets(ctx.block_id, block_cwd(ctx.block_id))
end)
