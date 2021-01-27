import XMonad
import XMonad.Config.Xfce
import XMonad.Util.Run (unsafeSpawn)

main = xmonad xfceConfig
  {
    terminal    = "/usr/local/bin/alacritty",
    modMask     = mod4Mask,
    startupHook = myStartupHook
  }

myStartupHook = do
  unsafeSpawn "$HOME/dotfiles/linux/xmonad.sh"
