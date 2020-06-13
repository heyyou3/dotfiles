.PHONY: init deploy change_sh install_tools

init: install_tools change_sh 

change_sh:
	chsh -s $(shell which zsh)

# [install tools]
# zsh
# zinit
# starship
# tmux
# neovim
# SpaceVim
ifeq ($(shell uname), Darwin)
install_tools:
	@echo '[OS:Mac] install tools' \
		&& brew uninstall zsh \
		&& brew install zsh
	@sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
	@sh -c "$(curl -fsSL https://starship.rs/install.sh)"
	@brew uninstall tmux
	@brew install tmux
	@brew uninstall neovim
	@brew install neovim
	@curl -sLf https://spacevim.org/install.sh | bash
else
install_tools:
	@echo '[OS:Linux] install tools' \
	&& cd /tmp/ \
	&& curl -OL https://sourceforge.net/projects/zsh/files/zsh/5.8/zsh-5.8.tar.xz/download \
	&& mv /tmp/download /tmp/zsh.tar.xz \
	&& tar xvf ./zsh.tar.xz \
	&& cd ./zsh-5.8 \
	&& ./configure --enable-multibyte \
	&& make \
	&& make install
	@sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
	@sh -c "$(curl -fsSL https://starship.rs/install.sh)"
	@git clone https://github.com/tmux/tmux.git /tmp/tmux \
		&& cd /tmp/tmux \
		&& sh autogen.sh \
		&& ./cofigure \
		&& make
	@cd /tmp/ \
		curl -OL https://github.com/neovim/neovim/releases/download/nightly/nvim.appimage \
		&& chmod u+x nvim.appimage \
		&& ./nvim.appimage
	@curl -sLf https://spacevim.org/install.sh | bash
endif

define _ln
	@ln -sfn $1 $2
endef

# after init
DOTFILES_PATH := "$(HOME)/dotfiles"
space_vim_d := Makefile
space_vim_init := .SpaceVim/init.vim
bash_profile := .bash_profile
bashrc := .bashrc
gitignore_global := .gitignore_global
tigrc := .tigrc
tmux_conf := .tmux.conf
vimrc := .vimrc
zshrc := .zshrc
zshenv := .zshenv

deploy:
	@$(call _ln,"$(DOTFILES_PATH)/$(space_vim_d)","$(HOME)/$(space_vim_d)")
	@$(call _ln,"$(DOTFILES_PATH)/$(space_vim_init)","$(HOME)/$(space_vim_init)")
	@$(call _ln,"$(DOTFILES_PATH)/bash/$(bash_profile)","$(HOME)/$(bash_profile)")
	@$(call _ln,"$(DOTFILES_PATH)/bash/$(bashrc)","$(HOME)/$(bashrc)")
	@$(call _ln,"$(DOTFILES_PATH)/git/$(gitignore_global)","$(HOME)/$(gitignore_global)")
	@$(call _ln,"$(DOTFILES_PATH)/tig/$(tigrc)","$(HOME)/$(tigrc)")
	@$(call _ln,"$(DOTFILES_PATH)/tmux/$(tmux_conf)","$(HOME)/$(tmux_conf)")
	@$(call _ln,"$(DOTFILES_PATH)/vim/$(vimrc)","$(HOME)/$(vimrc)")
	@$(call _ln,"$(DOTFILES_PATH)/zsh/$(zshrc)","$(HOME)/$(zshrc)")
	@$(call _ln,"$(DOTFILES_PATH)/zsh/$(zshenv)","$(HOME)/$(zshenv)")
