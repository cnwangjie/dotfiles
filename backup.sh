#!/bin/bash

# full path of this script
SCRIPT_FILE=`realpath $0`

# dir path of this script
FILE_PATH=`dirname $SCRIPT_FILE`

# script action: "backup" or "restore", default is backup
ACTION=$1

# judge $1 is newer than $2
newer() {
  if [ ! -e "$2" ]; then
    return 0
  elif [ ! -e "$1" ]; then
    return 1
  fi
  local oritime=`stat -c "%Y" $1`
  local dsttime=`stat -c "%Y" $2`
  if [ "$oritime" -gt "$dsttime" ]; then
    return 0
  else
    return 1
  fi
}

# judge $1 is same as $2
same() {
  if [ ! -e "$1" ]; then
    return 1
  elif [ ! -e "$2" ]; then
    return 1
  fi

  local hash1=`md5sum $1 | cut -d ' ' -f1`
  local hash2=`md5sum $2 | cut -d ' ' -f1`
  if [ "$hash1" = "$hash2" ]; then
    return 0
  else
    return 1
  fi
}

# copy $1 to $2
copy() {
  local src="$1"
  local dst="$2"

  if [ ! -e "$src" ]; then
    echo "$src not exists"
    return 1
  fi
  if (newer "$dst" "$src"); then
    echo "$dst newer than $src, sure replace? (y/N)"
    read sure
    if [ "$sure" != "y" ]; then
      return 1
    fi
  fi

  # create parent directory if not exists
  mkdir -p `dirname $dst`

  # copy file
  # -v display what is being done
  # -f force cover target file
  # -a recursion copy directory
  cp -v -f -a $src $dst
}

main() {
  # handle sourcemap file
  for section in $(cat sourcemap); do
    if [ "$loc" = "" ]; then
      local loc=`eval "echo $FILE_PATH/$section"`
    else
      local ori=`eval "echo $section"`
      if [ "$ACTION" = "restore" ]; then
        copy $loc $ori
      else
        copy $ori $loc
      fi
      local ori=''
      local loc=''
    fi
  done
}

main