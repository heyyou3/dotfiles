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
tigrc := .tigrc
tmux_conf := .tmux.conf
vimrc := .vimrc
zshenv := .zshenv
zshrc := .zshrc

common_deploy:
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

xmobarrc := .xmobarrc
xmonad_hs := xmonad.hs
xprofile := .xprofile

ifeq ($(shell uname), Linux)
deploy: common_deploy
	@echo 'Set Linux settings'
	@mkdir -p "$(HOME)/.xmonad"
	@$(call _ln,"$(DOTFILES_PATH)/linux/.xmonad/$(xmonad_hs)","$(HOME)/.xmonad/$(xmonad_hs)")
	@$(call _ln,"$(DOTFILES_PATH)/linux/$(xmobarrc)","$(HOME)/$(xmobarrc)")
	@mkdir -p "$(HOME)/.config/fcitx"
	@$(call _ln,"$(DOTFILES_PATH)/linux/fcitx/config","$(HOME)/.config/fcitx/config")
	@mkdir -p "$(HOME)/.config/rofi"
	@$(call _ln,"$(DOTFILES_PATH)/linux/.config/rofi/config.rasi","$(HOME)/.config/rofi/config.rasi")
else
deploy: common_deploy
endif

ifeq ($(shell uname), Linux)
install:
	@echo 'Install zinit'
	@sh -c "$$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
	@echo 'Install starship'
	@curl -fsSL https://starship.rs/install.sh | bash
	@echo 'Install tpm'
	@git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	@sudo apt update -y
	@curl https://sh.rustup.rs -sSf | sh
else
install:
	@echo 'Install zinit'
	@sh -c "$$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

	@echo 'Install starship'
	@curl -fsSL https://starship.rs/install.sh | bash
	@echo 'Install tpm'
	@git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	@curl https://sh.rustup.rs -sSf | sh
	@echo 'Mac Install Command'
	@echo 'brew install tig tmux fzf'
endif

nixos-build-desktop:
	sudo cp ./nix_config/configuration.nix /etc/nixos/configuration.nix
	sudo cp ./nix_config/hardware_desktop.nix /etc/nixos/hardware-configuration.nix
	sudo nixos-rebuild switch
nixos-build-thinkpad:
	sudo cp ./nix_config/configuration.nix /etc/nixos/configuration.nix
	sudo cp ./nix_config/hardware_thinkpad.nix /etc/nixos/hardware-configuration.nix
	sudo nixos-rebuild switch
nixos-build-thinkpad-t14:
	sudo cp ./nix_config/configuration.nix /etc/nixos/configuration.nix
	sudo cp ./nix_config/hardware_thinkpad_t14.nix /etc/nixos/hardware-configuration.nix
	sudo nixos-rebuild switch

