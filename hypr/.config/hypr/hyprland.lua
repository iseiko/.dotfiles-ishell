
-----------------
---- IMPORTS ----
-----------------


require("./modules/*")


-------------------
---- AUTOSTART ----
-------------------


hl.on("hyprland.start", function () 
   hl.exec_cmd("awww-daemon")
   hl.exec_cmd("sh -c 'sleep 1; awww img '$(cat ~/.cache/current_wall)''")
   hl.exec_cmd([[qs --log-rules "qt.qpa.wayland.textinput.warning=false"]])
   hl.exec_cmd(" hyprctl setcursor Bibata-Modern-Ice 24")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------


hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")

hl.env("QT_LOGGING_RULES", "qt.qpa.wayland.textinput.warning=false")


-----------------------
----- PERMISSIONS -----
-----------------------


-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


----------------
----  MISC  ----
----------------


hl.config({
    misc = {
        force_default_wallpaper = 1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
})

dofile(os.getenv("HOME") .. "/.config/hypr/theme.lua")
