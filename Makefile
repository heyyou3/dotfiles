.PHONY: common_deploy deploy

define _ln
	@ln -sfn $1 $2
endef

# [required tools]
# zsh
# zinit
# starship
# tmux
# neovim
# SpaceVim
# after init
DOTFILES_PATH := "$(HOME)/dotfiles"
alacritty := alacritty.yml
bash_profile := .bash_profile
bashrc := .bashrc
diff_highlight := diff-highlight
git_config := .gitconfig
gitignore_global := .gitignore_global
space_vim_init := .SpaceVim/init.vim
tigrc := .tigrc
tmux_conf := .tmux.conf
vimrc := .vimrc
zshenv := .zshenv
zshrc := .zshrc

common_deploy:
	@$(call _ln,"$(DOTFILES_PATH)/$(space_vim_init)","$(HOME)/$(space_vim_init)")
	@$(call _ln,"$(DOTFILES_PATH)/bash/$(bash_profile)","$(HOME)/$(bash_profile)")
	@$(call _ln,"$(DOTFILES_PATH)/bash/$(bashrc)","$(HOME)/$(bashrc)")
	@$(call _ln,"$(DOTFILES_PATH)/alacritty/$(alacritty)","$(HOME)/.config/$(alacritty)")
	@$(call _ln,"$(DOTFILES_PATH)/git/$(gitignore_global)","$(HOME)/$(gitignore_global)")
	@$(call _ln,"$(DOTFILES_PATH)/git/$(git_config)","$(HOME)/$(git_config)")
	@$(call _ln,"$(DOTFILES_PATH)/tig/$(tigrc)","$(HOME)/$(tigrc)")
	@$(call _ln,"$(DOTFILES_PATH)/tmux/$(tmux_conf)","$(HOME)/$(tmux_conf)")
	@$(call _ln,"$(DOTFILES_PATH)/vim/$(vimrc)","$(HOME)/$(vimrc)")
	@$(call _ln,"$(DOTFILES_PATH)/zsh/$(zshrc)","$(HOME)/$(zshrc)")
	@$(call _ln,"$(DOTFILES_PATH)/zsh/$(zshenv)","$(HOME)/$(zshenv)")
	@$(call _ln,"$(DOTFILES_PATH)/todo/.todo.cfg","$(HOME)/.todo.cfg")
	@sudo cp "$(DOTFILES_PATH)/git/$(diff_highlight)" "/usr/local/bin/$(diff_highlight)"

xmobarrc := .xmobarrc
xmonad_hs := xmonad.hs
xprofile := .xprofile

ifeq ($(shell uname), Linux)
deploy: common_deploy
	@echo 'Set Linux settings'
	@$(call _ln,"$(DOTFILES_PATH)/linux/$(xprofile)","$(HOME)/$(xprofile)")
	@mkdir -p "$(HOME)/.xmonad"
	@$(call _ln,"$(DOTFILES_PATH)/linux/.xmonad/$(xmonad_hs)","$(HOME)/.xmonad/$(xmonad_hs)")
	@$(call _ln,"$(DOTFILES_PATH)/linux/$(xmobarrc)","$(HOME)/$(xmobarrc)")
	@mkdir -p "$(HOME)/.config/fcitx"
	@$(call _ln,"$(DOTFILES_PATH)/linux/fcitx/config","$(HOME)/.config/fcitx/config")
	@mkdir -p "$(HOME)/.config/rofi"
	@$(call _ln,"$(DOTFILES_PATH)/linux/.config/rofi/config.rasi","$(HOME)/.config/rofi/config.rasi")
	@mkdir -p "$(HOME)/.config/ulauncher/user-themes"
	@$(call _ln,"$(DOTFILES_PATH)/linux/.config/ulauncher/user-themes/solarized-dark","$(HOME)/.config/ulauncher/user-themes/solarized-dark")
	@$(call _ln,"$(DOTFILES_PATH)/linux/.config/ulauncher/extensions.json","$(HOME)/.config/ulauncher/extensions.json")
	@$(call _ln,"$(DOTFILES_PATH)/linux/.config/ulauncher/settings.json","$(HOME)/.config/ulauncher/settings.json")
	@$(call _ln,"$(DOTFILES_PATH)/linux/.config/ulauncher/shortcuts.json","$(HOME)/.config/ulauncher/shortcuts.json")
else
deploy: common_deploy
endif

ifeq ($(shell uname), Linux)
install:
	@echo 'Install SpaceVim'
	@curl -sLf https://spacevim.org/install.sh | bash
	@echo 'Install zinit'
	@sh -c "$$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
	@echo 'Install starship'
	@curl -fsSL https://starship.rs/install.sh | bash
	@echo 'Install tpm'
	@git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	@sudo apt update -y
	@sudo apt install -y git tig tmux fzf xclip neovim fcitx fcitx-mozc xmonad xmobar compton feh breeze-cursor-theme make curl build-essential python3-pip python3 fonts-ricty-diminished cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev zsh rofi
	@sudo pip3 install neovim pynvim xkeysnail
	@curl https://sh.rustup.rs -sSf | sh
	@mkdir $(HOME)/work
	@git clone https://github.com/alacritty/alacritty $(HOME)/work/alacritty
	@chsh -s zsh
else
install:
	@echo 'Install SpaceVim'
	@curl -sLf https://spacevim.org/install.sh | bash
	@echo 'Install zinit'
	@sh -c "$$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
	@echo 'Install starship'
	@curl -fsSL https://starship.rs/install.sh | bash
	@echo 'Install tpm'
	@git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	@curl https://sh.rustup.rs -sSf | sh
	@echo 'Mac Install Command'
	@echo 'brew install tig tmux fzf'
endif
