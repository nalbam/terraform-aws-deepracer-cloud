#!/bin/sh

### BEGIN INIT INFO
# Provides:             dr-init
# Required-Start:       $local_fs $remote_fs
# Required-Stop:        $local_fs $remote_fs
# Should-Start:
# Should-Stop:
# Default-Start:        S
# Default-Stop:
# Short-Description:    Inform dr-init that /var/log is writable
### END INIT INFO

PATH="/sbin:/bin:/usr/sbin:/usr/bin"
NAME="dr-init"
DESC="AWS DeepRacer local"

set -e

case "${1}" in
        start)
                runuser -l ubuntu -c "~/run.sh"
                ;;

        stop|restart|force-reload)

                ;;

        *)
                echo "Usage: ${0} {start|stop|restart|force-reload}" >&2
                exit 1
                ;;
esac

exit 0
