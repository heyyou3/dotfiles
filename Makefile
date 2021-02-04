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
	@$(call _ln,"$(DOTFILES_PATH)/linux/.xmonad/$(xmonad_hs)","$(HOME)/.xmonad/$(xmonad_hs)")
	@$(call _ln,"$(DOTFILES_PATH)/linux/$(xmobarrc)","$(HOME)/$(xmobarrc)")
else
deploy: common_deploy
endif

install:
	@echo 'Install SpaceVim'
	@curl -sLf https://spacevim.org/install.sh | bash
	@echo 'Install zinit'
	@sh -c "$$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
	@echo 'Install starship'
	@curl -fsSL https://starship.rs/install.sh | bash
	@echo 'Install tpm'
	@git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	@echo 'LinuxMint Install Command'
	@echo 'sudo apt install tig tmux fzf xclip neovim fcitx fcitx-mozc xmonad xmobar compton feh'
	@echo 'sudo pip3 install xkeysnail'
	@echo 'Mac Install Command'
	@echo 'brew install tig tmux fzf'
