#!/bin/bash
# Author: Baptiste MOINE <bap.moine.86@gmail.com>
### BEGIN INIT INFO
# Provides:          barnyard2
# Required-Start:    $local_fs $mysqld $suricata
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 9
# Short-Description: Run Barnyard2 Daemon
# Description:       Barnyard2
### END INIT INFO

# Source function library.
if [ -f /etc/default/barnyard2 ]; then
    . /etc/default/barnyard2
else
    echo "/etc/default/barnyard2 is missing... bailing out!"
    exit 1
fi

# We'll add up all the options above and use them
NAME=barnyard2
DAEMON=/usr/local/bin/barnyard2
BARNYARD2_OPTIONS="-c ${SURCONF} -d ${SPOOL} -f ${PATTERN} -w ${WORKER} -D"

check_root()  {
    if [ "$(id -u)" != "0" ]; then
        log_failure_msg "You must be root to start, stop or restart ${NAME}."
        exit 1
    fi
}

success() {
    printf "%b%s%b\n" "\033[0;32m" "OK" "\033[0m"
}

failure() {
    printf "%b%s%b\n" "\033[0;31m" "Failed" "\033[0m"
}

start() {
    status 0
    if [[ ${?} == 0 ]]; then
        printf "${NAME} is already running\n"
        exit 0
    fi

    if [ -f ${PIDFILE} ]; then
        printf "PID file ${PIDFILE} alredy exists!\n"
        exit 1
    fi

    if [ ! -x ${DAEMON} ]; then
        printf "Daemon ${DAEMON} can't be found!\n"
        exit 1
    fi

    if [ ! -f ${SURCONF} ]; then
        printf "Configuration file ${SURCONF} can't be loaded!\n"
        exit 1
    fi

    echo -n "Starting ${NAME}: "
    RETVAL="`start-stop-daemon --quiet --start --oknodo --pidfile ${PIDFILE} --exec ${DAEMON} -- ${BARNYARD2_OPTIONS}`"

    if [[ ${?} == 0 ]]; then
        echo "${!}" >${PIDFILE}
        success
    else
        failure
        printf "%b${RETVAL}"
    fi
}

status() {
    if [ -s ${PIDFILE} ]; then
        PID=`cat ${PIDFILE}`
        if kill -0 "${PID}" 2>/dev/null; then
            [[ ${1} == 1 ]] && printf "${NAME} is running with PID ${PID}\n"
            RETVAL=0
        else
            [[ ${1} == 1 ]] && printf "PID file ${PIDFILE} exists, but process not running!\n"
            RETVAL=1
        fi
    else
        [[ ${1} == 1 ]] && printf "${NAME} is not running\n"
        RETVAL=1
    fi

    return ${RETVAL}
}

stop() {
    status 0

    if [[ ${?} == 1 ]]; then
        printf "${NAME} is not running\n"
        rm -f ${PIDFILE}
        exit 0
    fi

    echo -n "Stopping ${NAME}: "
    start-stop-daemon --quiet --stop --remove-pidfile --quiet --oknodo --retry 30 --pidfile ${PIDFILE} && success || failure
}

check_root

case "$1" in
    start)
        ${1}
        status
    ;;
    stop)
        ${1}
    ;;
    status)
        ${1} 1
    ;;
    restart)
        stop
        start
        status 1
    ;;
    *)
        printf "Usage: $0 {start|stop|restart|status}\n"
        exit 1
    ;;
esac

exit 0
