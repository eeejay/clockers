#!/bin/bash

_HOURS="26 27 28 29 25"
_MINUTES="0 2 1 4 24"
_SECONDS="5 6 10 11 23"

case "$1" in
  hours)
    ./step $_HOURS $2 $3
    ;;
  minutes)
    ./step $_MINUTES $2 $3
    ;;
  seconds)
    ./step $_SECONDS $2 $3
    ;;
  zero)
    ./step $_HOURS 7200 12 & ./step $_MINUTES 7200 12 & ./step $_SECONDS 7200 12
    ;;
  *)
    ;;
esac
