-- Move Toggle Sidebar from its default (cmd+/) to cmd+b
rex.unbind("cmd+/", "client.sidebar.toggle")
rex.bind("cmd+b", "client.sidebar.toggle")

-- Send cmd+k to the terminal, and open the session switcher with cmd+p
rex.unbind("cmd+k")
rex.bind("cmd+p", "session.switch")

-- cmd+r: in a Cargo project, open a floating pane that lists bin, example, and bench targets
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

-- Open the target picker in a floating pane. Returns false if dir isn't in a Cargo project.
local function open_cargo_targets(dir)
  local root = cargo_root(dir)
  if not root then return false end
  local _, err = rex.session.new_layer{
    bounds = { 0.1, 0.1, 0.8, 0.8 },
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
  description = "Pick a bin, example, or bench target in the current Cargo project and run it in a floating pane.",
  keywords = "rust cargo bench example run build",
  args = { dir = "string?" },
  run = function(ctx, args)
    local dir = args.dir or block_cwd(ctx.block_id)
    if not open_cargo_targets(dir) then
      error("not in a Cargo project: " .. tostring(dir), 0)
    end
  end,
}

rex.bind("cmd+r", function(ctx, ev)
  return open_cargo_targets(block_cwd(ctx.block_id))
end)
