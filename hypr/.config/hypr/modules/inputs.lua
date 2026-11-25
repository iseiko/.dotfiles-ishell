
---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

hl.gesture({
  fingers = 3,
  direction = "vertical",
  action = "special",
  workspace_name = "magic"
})

hl.device({
    name = "dualsense-wireless-controller-touchpad",
    enabled = false,
})

