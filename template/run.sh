#!/usr/bin/env bash

CMD=$1

if [ "${CMD}" == "init" ]; then
  chmod 755 ~/run.sh
  sudo cp ~/run.sh /etc/init.d/autostart.sh
  sudo update-rc.d autostart.sh defaults
  exit 0
fi

if [ ! -f ~/.autostarted ]; then
  pushd ~/deepracer-for-cloud
  ./bin/init.sh -c aws -a gpu
  popd
  touch ~/.autostarted
fi
