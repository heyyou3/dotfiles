import System.IO
import System.Exit
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.SetWMName
import XMonad.Hooks.FadeInactive
import XMonad.Util.Run
import XMonad.Util.EZConfig

-- Layouts
import XMonad.Layout.Fullscreen
import XMonad.Layout.GridVariants (Grid(Grid))
import XMonad.Layout.NoBorders
import XMonad.Layout.PerWorkspace(onWorkspace)
import XMonad.Layout.ResizableTile
import XMonad.Layout.SimplestFloat
import XMonad.Layout.Spiral
import XMonad.Layout.Tabbed
import XMonad.Layout.ThreeColumns
import XMonad.Layout.IndependentScreens

-- Layouts modifiers
import XMonad.Layout.LayoutModifier
import XMonad.Layout.LimitWindows (limitWindows, increaseLimit, decreaseLimit)
import XMonad.Layout.Magnifier
import XMonad.Layout.MultiToggle (mkToggle, single, EOT(EOT), (??))
import XMonad.Layout.MultiToggle.Instances (StdTransformers(NBFULL, MIRROR, NOBORDERS))
import XMonad.Layout.NoBorders
import XMonad.Layout.Renamed
import XMonad.Layout.ShowWName
import XMonad.Layout.Simplest
import XMonad.Layout.Spacing
import XMonad.Layout.SubLayouts
import XMonad.Layout.WindowNavigation
import XMonad.Layout.WindowArranger (windowArrange, WindowArrangerMsg(..))
import qualified XMonad.Layout.ToggleLayouts as T (toggleLayouts, ToggleLayout(Toggle))
import qualified XMonad.Layout.MultiToggle as MT (Toggle(..))

-- Actions
import XMonad.Actions.Warp

import qualified XMonad.StackSet as W
import qualified Data.Map as M
import Data.Ratio

------------------------------------------------------------------------
-- Terminal
-- The preferred terminal program, which is used in a binding below and by
-- certain contrib modules.
--
myTerminal = "/usr/local/bin/alacritty"

------------------------------------------------------------------------
-- Workspaces
-- The default number of workspaces (virtual screens) and their names.
--
myWorkspaces = ["A","B","C","D","E","F","G","H","I"]

------------------------------------------------------------------------
-- Layouts
-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
--
-- The available layouts. Note that each layout is separated by |||,
-- which denotes layout choice.
myFont = "Cica"

------------------------------------------------------------------------
-- Colors and borders
--
myNormalBorderColor = "#002b36"
myFocusedBorderColor = "#657b83"

-- Colors for text and backgrounds of each tab when in "Tabbed" layout.
myTabTheme = def {
    fontName = myFont,
    activeBorderColor = "#7C7C7C",
    activeTextColor = "#CEFFAC",
    activeColor = "#000000",
    inactiveBorderColor = "#7C7C7C",
    inactiveTextColor = "#EEEEEE",
    inactiveColor = "#000000"
}

--Makes setting the spacingRaw simpler to write. The spacingRaw module adds a configurable amount of space around windows.
mySpacing :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing i = spacingRaw False (Border i i i i) True (Border i i i i) True

-- Below is a variation of the above except no borders are applied
-- if fewer than two windows. So a single window has no gaps.
mySpacing' :: Integer -> l a -> XMonad.Layout.LayoutModifier.ModifiedLayout Spacing l a
mySpacing' i = spacingRaw True (Border i i i i) True (Border i i i i) True


-- Defining a bunch of layouts, many that I don't use.
-- limitWindows n sets maximum number of windows displayed for layout.
-- mySpacing n sets the gap size around the windows.
tall     = renamed [Replace "tall"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (Simplest)
           $ limitWindows 12
           $ mySpacing 10
           $ ResizableTall 1 (3/100) (1/2) []
magnify  = renamed [Replace "magnify"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (Simplest)
           $ magnifier
           $ limitWindows 12
           $ mySpacing 10
           $ ResizableTall 1 (3/100) (1/2) []
monocle  = renamed [Replace "monocle"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (Simplest)
           $ limitWindows 20 Full
floats   = renamed [Replace "floats"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (Simplest)
           $ limitWindows 20 simplestFloat
grid     = renamed [Replace "grid"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (Simplest)
           $ limitWindows 12
           $ mySpacing 0
           $ mkToggle (single MIRROR)
           $ Grid (16/10)
spirals  = renamed [Replace "spirals"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (Simplest)
           $ mySpacing' 10
           $ spiral (6/7)
threeCol = renamed [Replace "threeCol"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (Simplest)
           $ limitWindows 7
           $ mySpacing' 10
           $ ThreeCol 1 (3/100) (1/2)
threeRow = renamed [Replace "threeRow"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] (Simplest)
           $ limitWindows 7
           $ mySpacing' 10
           -- Mirror takes a layout and rotates it by 90 degrees.
           -- So we are applying Mirror to the ThreeCol layout.
           $ Mirror
           $ ThreeCol 1 (3/100) (1/2)
tabs     = renamed [Replace "tabs"]
           -- I cannot add spacing to this layout because it will
           -- add spacing between window and tabs which looks bad.
           $ tabbed shrinkText myTabTheme

-- Color of current window title in xmobar.
xmobarTitleColor = "#859900"

-- Color of current workspace in xmobar.
xmobarCurrentWorkspaceColor = "#CEFFAC"

-- Width of the window border in pixels.
myBorderWidth = 2

------------------------------------------------------------------------
-- Key bindings
--
-- modMask lets you specify which modkey you want to use. The default
-- is mod1Mask ("left alt"). You may also consider using mod3Mask
-- ("right alt"), which does not conflict with emacs keybindings. The
-- "windows key" is usually mod4Mask.
--
myModMask = mod4Mask
toggleStructsKey :: XConfig t -> (KeyMask, KeySym)
toggleStructsKey XConfig { XMonad.modMask = modMask } = ( modMask, xK_b )

------------------------------------------------------------------------
-- Mouse bindings
--
-- Focus rules
-- True if your focus should follow your mouse cursor.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = False

myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList $
  [
    -- mod-button1, Set the window to floating mode and move by dragging
    ((modMask, button1),
     (\w -> focus w >> mouseMoveWindow w))

    -- mod-button2, Raise the window to the top of the stack
    , ((modMask, button2),
       (\w -> focus w >> windows W.swapMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modMask, button3),
       (\w -> focus w >> mouseResizeWindow w))

    -- you may also bind events to the mouse scroll wheel (button4 and button5)
  ]

-- | Number of windows in a possibly empty stack.
windowCount :: Maybe (W.Stack Window) -> Int
windowCount Nothing = 0
windowCount (Just (W.Stack focus up dn)) = 1 + length up + length dn

-- | Move the mouse cursor to the center of the current window.
warp :: X ()
warp = warpToWindow (1%2) (2%5)

-- | Move the mouse cursor to the center of the current screen.
warpScreen :: X ()
warpScreen = do
  ws <- gets windowset
  let screen = W.screen . W.current $ ws
  warpToScreen screen (1%2) (1%2)

-- | Move the mouse cursor to the center of the current window. If
-- there are no windows, center the cursor on the screen.
warp' :: X ()
warp' = do
  windowCount <- currentWindowCount
  if windowCount == 0
    then warpScreen
    else warp

-- | Current workspace window stack.
currentStack :: X (Maybe (W.Stack Window))
currentStack = (W.stack . W.workspace . W.current) <$> gets windowset

-- | Number of windows on the current workspace.
currentWindowCount :: X Int
currentWindowCount = windowCount <$> currentStack

------------------------------------------------------------------------
-- Startup hook
-- Perform an arbitrary action each time xmonad starts or is restarted
-- with mod-q. Used by, e.g., XMonad.Layout.PerWorkspace to initialize
-- per-workspace layout choices.
--
-- By default, do nothing.
myStartupHook = do
  unsafeSpawn "$HOME/dotfiles/linux/xmonad.sh"

------------------------------------------------------------------------
-- Floats all windows in a certain workspace.

-- The layout hook
myLayoutHook = avoidStruts $ windowArrange $ T.toggleLayouts floats
               $ mkToggle (NBFULL ?? NOBORDERS ?? EOT) myDefaultLayout
             where
               myDefaultLayout =     tall
                                 ||| magnify
                                 ||| noBorders monocle
                                 ||| floats
                                 ||| noBorders tabs
                                 ||| grid
                                 ||| spirals
                                 ||| threeCol
                                 ||| threeRow

------------------------------------------------------------------------
-- Combine it all together
-- A structure containing your configuration settings, overriding
-- fields in the default config. Any you don't override, will
-- use the defaults defined in xmonad/XMonad/Config.hs
--
-- No need to modify this.
--
defaults = def {
    -- simple stuff
    terminal = myTerminal,
    focusFollowsMouse = myFocusFollowsMouse,
    borderWidth = myBorderWidth,
    modMask = myModMask,
    workspaces = myWorkspaces,
    normalBorderColor = myNormalBorderColor,
    focusedBorderColor = myFocusedBorderColor,

    mouseBindings = myMouseBindings,

    -- hooks, layouts
    -- defaultLayouts = smartBorders $ myLayout,
    -- layoutHook = myLayouts,
    startupHook = myStartupHook
}

myConfig = defaults {
  manageHook = manageDocks <+> manageHook defaults,
  layoutHook = myLayoutHook
}

myLogHook :: X()
myLogHook = fadeInactiveLogHook fadeAmount
  where fadeAmount = 0.9


------------------------------------------------------------------------
-- Run xmonad with all the defaults we set up.
--
--main = xmonad =<< xmobar defaultConfig { terminal = "urxvt" }
main = do
  n <- countScreens
  xmprocs <- mapM (\i -> spawnPipe $ "xmobar $HOME/dotfiles/linux/.xmobarrc" ++ " -x " ++ show i) [0..n-1]
  xmonad $ myConfig {
    logHook = mapM_ (\handle -> dynamicLogWithPP $ xmobarPP {
      ppOutput = hPutStrLn handle
        , ppCurrent = xmobarColor "#c3e88d" "" . wrap "[" "]" -- Current workspace in xmobar
        , ppVisible = xmobarColor "#c3e88d" ""                -- Visible but not current workspace
        , ppHidden = xmobarColor "#82AAFF" "" . wrap "*" ""   -- Hidden workspaces in xmobar
        , ppHiddenNoWindows = xmobarColor "#F07178" ""        -- Hidden workspaces (no windows)
        , ppTitle = xmobarColor "#d0d0d0" "" . shorten 60     -- Title of active window in xmobar
        , ppSep =  "<fc=#666666> | </fc>"                     -- Separators in xmobar
        , ppUrgent = xmobarColor "#C45500" "" . wrap "!" "!"  -- Urgent workspace
        , ppOrder  = \(ws:l:t:ex) -> [ws,l]++ex++[t]
    }) xmprocs
  }
