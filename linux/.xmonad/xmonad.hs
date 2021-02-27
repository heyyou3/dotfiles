import           System.Exit
import           System.IO
import           XMonad
import           XMonad.Hooks.DynamicLog
import           XMonad.Hooks.FadeInactive
import           XMonad.Hooks.ManageDocks
import           XMonad.Hooks.ManageHelpers
import           XMonad.Hooks.SetWMName
import           XMonad.Util.EZConfig
import           XMonad.Util.Run

-- Layouts
import           XMonad.Layout.Fullscreen
import           XMonad.Layout.GridVariants          (Grid (Grid))
import           XMonad.Layout.IndependentScreens
import           XMonad.Layout.NoBorders
import           XMonad.Layout.PerWorkspace          (onWorkspace)
import           XMonad.Layout.ResizableTile
import           XMonad.Layout.SimplestFloat
import           XMonad.Layout.Spiral
import           XMonad.Layout.Tabbed
import           XMonad.Layout.ThreeColumns

-- Layouts modifiers
import           XMonad.Layout.LayoutModifier
import           XMonad.Layout.LimitWindows          (decreaseLimit,
                                                      increaseLimit,
                                                      limitWindows)
import           XMonad.Layout.Magnifier
import           XMonad.Layout.MultiToggle           (EOT (EOT), mkToggle,
                                                      single, (??))
import qualified XMonad.Layout.MultiToggle           as MT (Toggle (..))
import           XMonad.Layout.MultiToggle.Instances (StdTransformers (MIRROR, NBFULL, NOBORDERS))
import           XMonad.Layout.Renamed
import           XMonad.Layout.ShowWName
import           XMonad.Layout.Simplest
import           XMonad.Layout.Spacing
import           XMonad.Layout.SubLayouts
import qualified XMonad.Layout.ToggleLayouts         as T (ToggleLayout (Toggle),
                                                           toggleLayouts)
import           XMonad.Layout.WindowArranger        (WindowArrangerMsg (..),
                                                      windowArrange)
import           XMonad.Layout.WindowNavigation

-- Actions
import           XMonad.Actions.CycleWS
import           XMonad.Actions.Warp

import qualified Data.Map                            as M
import           Data.Ratio
import qualified XMonad.StackSet                     as W

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
myFont = "xft:RictyDiminished-Regular:size=10:bold:antialias=true"

------------------------------------------------------------------------
-- Colors and borders
--
myNormalBorderColor = "#002b36"
myFocusedBorderColor = "#6c71c4"

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
           $ subLayout [] Simplest
           $ limitWindows 12
           $ mySpacing 10
           $ ResizableTall 1 (3/100) (1/2) []
magnify  = renamed [Replace "magnify"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] Simplest
           $ magnifier
           $ limitWindows 12
           $ mySpacing 10
           $ ResizableTall 1 (3/100) (1/2) []
monocle  = renamed [Replace "monocle"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ noBorders
           $ subLayout [] Simplest
           $ limitWindows 20 Full
grid     = renamed [Replace "grid"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] Simplest
           $ limitWindows 12
           $ mySpacing 0
           $ mkToggle (single MIRROR)
           $ Grid (16/10)
spirals  = renamed [Replace "spirals"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] Simplest
           $ mySpacing' 10
           $ spiral (6/7)
threeCol = renamed [Replace "threeCol"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] Simplest
           $ limitWindows 7
           $ mySpacing' 10
           $ ThreeCol 1 (3/100) (1/2)
threeRow = renamed [Replace "threeRow"]
           $ windowNavigation
           $ addTabs shrinkText myTabTheme
           $ subLayout [] Simplest
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

myDefaultKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myDefaultKeys conf@XConfig { XMonad.modMask = modMask } = M.fromList $ [
  ((modMask .|. shiftMask, xK_Return), spawn $ XMonad.terminal conf) -- %! Launch terminal
    , ((modMask,               xK_space ), sendMessage NextLayout) -- %! Rotate through the available layout algorithms
    , ((modMask .|. shiftMask, xK_space ), setLayout $ XMonad.layoutHook conf) -- %!  Reset the layouts on the current workspace to default

    -- move focus up or down the window stack
    , ((modMask,               xK_j     ), windows W.focusDown) -- %! Move focus to the next window
    , ((modMask,               xK_k     ), windows W.focusUp  ) -- %! Move focus to the previous window
    , ((modMask,               xK_m     ), windows W.focusMaster  ) -- %! Move focus to the master window

    -- modifying the window order
    , ((modMask,               xK_Return), windows W.swapMaster) -- %! Swap the focused window and the master window
    , ((modMask .|. shiftMask, xK_j     ), windows W.swapDown  ) -- %! Swap the focused window with the next window
    , ((modMask .|. shiftMask, xK_k     ), windows W.swapUp    ) -- %! Swap the focused window with the previous window

    -- resizing the master/slave ratio
    , ((modMask,               xK_h     ), sendMessage Shrink) -- %! Shrink the master area
    , ((modMask,               xK_l     ), sendMessage Expand) -- %! Expand the master area

    -- floating layer support
    , ((modMask,               xK_t     ), withFocused $ windows . W.sink) -- %! Push window back into tiling

    -- increase or decrease number of windows in the master area
    , ((modMask              , xK_comma ), sendMessage (IncMasterN 1)) -- %! Increment the number of windows in the master area
    , ((modMask              , xK_period), sendMessage (IncMasterN (-1))) -- %! Deincrement the number of windows in the master area

    -- quit, or restart
    , ((modMask              , xK_q     ), spawn "if type xmonad; then xmonad --recompile && xmonad --restart; else xmessage xmonad not in \\$PATH: \"$PATH\"; fi") -- %! Restart xmonad

    , ((modMask .|. shiftMask, xK_slash ), helpCommand) -- %! Run xmessage with a summary of the default keybindings (useful for beginners)
    -- repeat the binding for non-American layout keyboards
    , ((modMask              , xK_question), helpCommand) -- %! Run xmessage with a summary of the default keybindings (useful for beginners)
    ]
    ++
    -- mod-[1..9] %! Switch to workspace N
    -- mod-shift-[1..9] %! Move client to workspace N
    [((m .|. modMask, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9]
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]
    ++
    -- mod-{w,e,r} %! Switch to physical/Xinerama screens 1, 2, or 3
    -- mod-shift-{w,e,r} %! Move client to screen 1, 2, or 3
    [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]
  where
    helpCommand :: X ()
    helpCommand = spawn ("echo " ++ show help ++ " | xmessage -file -")

-- My Original Keybinds
myKeys = [
    ("M-c", kill),
    ("M-a", warp'),
    ("M-f", sendMessage (T.Toggle "monocle")),
    ("M-/", spawn "rofi -show drun"),
    ("M-v", spawn "nvim-qt \"/tmp/$(date '+%Y%m%d%H%M%S').anyware\""),
    ("M-S-s", spawn "$HOME/dotfiles/linux/screenshot.sh"),
    ("M-n", nextWS),
    ("M-p", prevWS),
    ("M-<Tab>", nextScreen),
    ("M-C-<Tab>", prevScreen)
  ]

help :: String
help = unlines ["The default modifier key is 'Super'. Default keybindings:",
    "",
    "-- launching and killing programs",
    "mod-Shift-Enter  Launch xterminal",
    "mod-c      Close/kill the focused window",
    "mod-Space        Rotate through the available layout algorithms",
    "mod-Shift-Space  Reset the layouts on the current workSpace to default",
    "mod-n            Next WorkSpace",
    "mod-p            Previous WorkSpace",
    "",
    "-- move focus up or down the window stack",
    "mod-Tab        Move focus to the next Screen",
    "mod-Control-Tab  Move focus to the previous Screen",
    "mod-j          Move focus to the next window",
    "mod-k          Move focus to the previous window",
    "mod-m          Move focus to the master window",
    "",
    "-- modifying the window order",
    "mod-Return   Swap the focused window and the master window",
    "mod-Shift-j  Swap the focused window with the next window",
    "mod-Shift-k  Swap the focused window with the previous window",
    "",
    "-- resizing the master/slave ratio",
    "mod-h  Shrink the master area",
    "mod-l  Expand the master area",
    "",
    "-- floating layer support",
    "mod-t  Push window back into tiling; unfloat and re-tile it",
    "",
    "-- increase or decrease number of windows in the master area",
    "mod-comma  (mod-,)   Increment the number of windows in the master area",
    "mod-period (mod-.)   Deincrement the number of windows in the master area",
    "",
    "-- quit, or restart",
    "mod-q        Restart xmonad",
    "",
    "-- Workspaces & screens",
    "mod-[1..9]         Switch to workSpace N",
    "mod-Shift-[1..9]   Move client to workspace N",
    "mod-{w,e,r}        Switch to physical/Xinerama screens 1, 2, or 3",
    "mod-Shift-{w,e,r}  Move client to screen 1, 2, or 3",
    "",
    "-- Mouse bindings: default actions bound to mouse events",
    "mod-button1  Set the window to floating mode and move by dragging",
    "mod-button2  Raise the window to the top of the stack",
    "mod-button3  Set the window to floating mode and resize by dragging"]
------------------------------------------------------------------------
-- Mouse bindings
--
-- Focus rules
-- True if your focus should follow your mouse cursor.
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = False

myMouseBindings XConfig {XMonad.modMask = modMask} = M.fromList
  [
    -- mod-button1, Set the window to floating mode and move by dragging
    ((modMask, button1),
     \w -> focus w >> mouseMoveWindow w)

    -- mod-button2, Raise the window to the top of the stack
    , ((modMask, button2),
       \w -> focus w >> windows W.swapMaster)

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modMask, button3),
       \w -> focus w >> mouseResizeWindow w)

    -- you may also bind events to the mouse scroll wheel (button4 and button5)
  ]

-- | Number of windows in a possibly empty stack.
windowCount :: Maybe (W.Stack Window) -> Int
windowCount Nothing                      = 0
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
currentStack = W.stack . W.workspace . W.current <$> gets windowset

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
myLayoutHook = avoidStruts $ windowArrange $ T.toggleLayouts monocle $ mkToggle (NBFULL ?? NOBORDERS ?? EOT) myDefaultLayout
             where
               myDefaultLayout =     tall
                                 ||| magnify
                                 ||| monocle
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

    keys = myDefaultKeys,
    mouseBindings = myMouseBindings,

    -- hooks, layouts
    -- defaultLayouts = smartBorders $ myLayout,
    -- layoutHook = myLayouts,
    startupHook = myStartupHook
}

myConfig = defaults {
  manageHook = manageDocks <+> manageHook defaults,
  layoutHook = myLayoutHook
} `additionalKeysP` myKeys

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
