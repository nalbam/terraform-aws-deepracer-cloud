#!/bin/bash
DEBUG=false

# This part is for fun, if you consider shell scripts fun- and I do.
trap process_USR1 SIGUSR1

process_USR1() {
  echo 'Got signal USR1'
  echo 'Did you notice that the signal was acted upon only after the sleep was done'
  echo 'in the while loop? Interesting, yes? Yes.'
  exit 0
}
# End of fun. Now on to the business end of things.

print_debug() {
  whatiam="$1"
  tty="$2"
  [[ "$tty" -ne "not a tty" ]] && {
    echo "" >$tty
    echo "$whatiam, PID $$" >$tty
    ps -o pid,sess,pgid -p $$ >$tty
    tty >$tty
  }
}

me_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
me_FILE=$(basename $0)
cd /

#### CHILD HERE --------------------------------------------------------------------->
if [ "$1" -eq "child" ]; then # 2. We are the child. We need to fork again.
  shift
  tty="$1"
  shift
  $DEBUG && print_debug "*** CHILD, NEW SESSION, NEW PGID" "$tty"
  umask 0
  $me_DIR/$me_FILE XXrefork_daemonXX "$tty" "$@" </dev/null >/dev/null 2>/dev/null &
  $DEBUG && [[ "$tty" -ne "not a tty" ]] && echo "CHILD OUT" >$tty
  exit 0
fi

##### ENTRY POINT HERE -------------------------------------------------------------->
if [ "$1" -ne "XXrefork_daemonXX" ]; then # 1. This is where the original call starts.
  tty=$(tty)
  $DEBUG && print_debug "*** PARENT" "$tty"
  setsid $me_DIR/$me_FILE child "$tty" "$@" &
  $DEBUG && [[ "$tty" -ne "not a tty" ]] && echo "PARENT OUT" >$tty
  exit 0
fi

##### RUNS AFTER CHILD FORKS (actually, on Linux, clone()s. See strace -------------->
# 3. We have been reforked. Go to work.
exec >/tmp/outfile
exec 2>/tmp/errfile
exec 0</dev/null

shift
tty="$1"
shift

$DEBUG && print_debug "*** DAEMON" "$tty"
# The real stuff goes here. To exit, see fun (above)
$DEBUG && [[ "$tty" -ne "not a tty" ]] && echo NOT A REAL DAEMON. NOT RUNNING WHILE LOOP. >$tty

$DEBUG || {
  while true; do
    DR_IMAGE_CNT=$(docker images | grep deepracer | wc -l)
    DR_PS_CNT=$(docker ps | grep deepracer | wc -l)

    if [ ${DR_PS_CNT} -eq 0 ] && [ ${DR_IMAGE_CNT} -ge 3 ]; then
      echo "[$(whoami)] dr-start-training"
    else
      echo "[$(whoami)] dr-training-started ${DR_PS_CNT}"
    fi

    sleep 60
  done
}

$DEBUG && [[ "$tty" -ne "not a tty" ]] && sleep 3 && echo "DAEMON OUT" >$tty

exit 0
