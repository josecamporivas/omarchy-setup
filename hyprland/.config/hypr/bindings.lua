-- Personal keybinding overrides. Loaded after Omarchy's defaults.

-- SUPER + SHIFT + M: Music TUI (cliamp) instead of the default Music/Spotify.
hl.unbind("SUPER + SHIFT + M")
o.bind("SUPER + SHIFT + M", "Music TUI", { tui = "cliamp", focus = true })

-- SUPER + SHIFT + E: Editor instead of the default Email.
hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Editor", { omarchy = "editor" })

-- SUPER + SHIFT + C: ChatGPT instead of the default Calendar.
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "ChatGPT", { webapp = "https://chatgpt.com" })

-- SUPER + SHIFT + G: Grok instead of the default Signal.
hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "Grok", { webapp = "https://grok.com" })

-- Manual window resizing with SUPER + ALT + arrows.
-- Overrides Omarchy's default SUPER + ALT + arrows (move window into a group).
hl.unbind("SUPER + ALT + LEFT")
hl.unbind("SUPER + ALT + RIGHT")
hl.unbind("SUPER + ALT + UP")
hl.unbind("SUPER + ALT + DOWN")
o.bind("SUPER + ALT + RIGHT", "Resize window right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
o.bind("SUPER + ALT + LEFT", "Resize window left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
o.bind("SUPER + ALT + UP", "Resize window up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
o.bind("SUPER + ALT + DOWN", "Resize window down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })
