#!/bin/bash

# To backup dotfiles
FILE_LIST="
.atom/init.coffee
.tmux.conf
.zshrc
"

CURRENT_PATH=`dirname $0`

copy() {
  local src="$HOME/$1"
  local dst="$CURRENT_PATH/$1"
  mkdir -p `dirname $dst`
  cp -v -f -a $src $dst
}

for FILE in $FILE_LIST; do
  if [ ! -e "$HOME/$FILE" ]; then
    echo $FILE 'not exists'
    continue
  fi

  copy $FILE
done
