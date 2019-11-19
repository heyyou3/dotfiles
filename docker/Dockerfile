FROM ubuntu:18.10

RUN apt-get update -y \
  && apt-get install -y \
  vim \
  git \
  tmux \
  curl \
  zsh \
  gawk \
  && git clone https://github.com/NishidaYuhei/dotfiles.git /root/dotfiles \
  && git clone https://github.com/zplug/zplug /root/.zplug \
  && /bin/bash /root/dotfiles/set_synbolic_link.sh

WORKDIR /root

CMD ["/usr/bin/zsh"]
