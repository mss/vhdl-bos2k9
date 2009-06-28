#!/bin/bash
# TODO

pfile=${0%.*}
qfile=${pfile%.mpf}.qsf

set_global_assignment() {
  local name arg lib
   while [ $# -gt 0 ]; do
    case "$1" in
      -name)
        name=$2
        arg=$3
        shift 2
      ;;
      -library)
        lib=$2
        shift 1
      ;;
    esac
    shift
  done
  lib=${lib:-work}
  case "$name" in
    PROJECT_OUTPUT_DIRECTORY)
      outdir=$arg
    ;;
    VHDL_FILE)
      echo $arg $lib
    ;;
  esac
}

while read cmd line; do
  if type "$cmd" > /dev/null 2>&1; then
    "$cmd" $line
  fi
done < $qfile

