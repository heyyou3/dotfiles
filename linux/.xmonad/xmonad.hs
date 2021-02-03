import System.IO
import System.Exit
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Layout.Fullscreen
import XMonad.Layout.NoBorders
import XMonad.Layout.SimplestFloat
import XMonad.Layout.Spiral
import XMonad.Layout.PerWorkspace(onWorkspace)
import XMonad.Layout.Tabbed
import XMonad.Util.Run
import XMonad.Util.EZConfig(additionalKeys)
import qualified XMonad.StackSet as W
import qualified Data.Map as M

defaults = defaultConfig {
    terminal    = "/usr/local/bin/alacritty",
    modMask     = mod4Mask,
    focusFollowsMouse = myFocusFollowsMouse,
    borderWidth = myBorderWidth,
    normalBorderColor = myNormalBorderColor,
    focusedBorderColor = myFocusedBorderColor,
    startupHook = myStartupHook
}

main = do
  xmonad $ defaults

myStartupHook = do
  unsafeSpawn "$HOME/dotfiles/linux/xmonad.sh"

defaultLayouts = avoidStruts (
    Tall 1 (3/100) (1/2) |||
    Mirror (Tall 1 (3/100) (1/2)) |||
    tabbed shrinkText tabConfig |||
    Full |||
    spiral (6/7)) |||
    noBorders (fullscreenFull Full)

------------------------------------------------------------------------
-- Colors and borders
--
myNormalBorderColor = "#002b36"
myFocusedBorderColor = "#657b83"

-- Colors for text and backgrounds of each tab when in "Tabbed" layout.
tabConfig = defaultTheme {
    activeBorderColor = "#7C7C7C",
    activeTextColor = "#CEFFAC",
    activeColor = "#000000",
    inactiveBorderColor = "#7C7C7C",
    inactiveTextColor = "#EEEEEE",
    inactiveColor = "#000000"
}

-- Color of current window title in xmobar.
xmobarTitleColor = "green"

-- Color of current workspace in xmobar.
xmobarCurrentWorkspaceColor = "#CEFFAC"

-- Width of the window border in pixels.
myBorderWidth = 1

------------------------------------------------------------------------
-- Mouse bindings
--
-- Focus rules
-- True if your focus should follow your mouse cursor.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = False

------------------------------------------------------------------------
-- Floats all windows in a certain workspace.
-- myLayouts
myLayouts = onWorkspace "three" simplestFloat $ defaultLayouts
