-- Personal input overrides. Loaded after Omarchy's defaults.

hl.config({
  input = {
    touchpad = {
      natural_scroll = true,
      -- Omarchy defaults to two-finger right-click. Use the lower-right
      -- corner for right-click instead.
      clickfinger_behavior = false,
    },
  },
})

-- Per-device pointer speed: only the built-in clickpad, not the USB mouse.
-- Increase in small steps (0.2 -> 0.25 -> 0.3) if needed.
hl.device({
  name = "syna7db5:00-06cb:cd41-touchpad",
  sensitivity = 0.2,
})
