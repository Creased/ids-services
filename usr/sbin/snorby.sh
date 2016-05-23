#!/bin/bash
# Author: Baptiste MOINE <bap.moine.86@gmail.com>
### BEGIN INIT INFO
# Provides:          snorby
# Required-Start:    $local_fs $mysqld $suricata $barnyard2
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 9
# Short-Description: Run Snorby Daemon
# Description:       Snorby Frontend
### END INIT INFO

# Source function library.
if [ -f /etc/default/snorby ]; then
    . /etc/default/snorby
else
    echo "/etc/default/snorby is missing... bailing out!"
    exit 1
fi

# We'll add up all the options above and use them
NAME=snorby
DAEMON=/usr/local/rvm/gems/ruby-1.9.3-p551/bin/bundle
SNORBY_OPTIONS="exec rails server -e ${ENVIRONMENT} -b ${HOST} -p ${PORT} -d"

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

    echo -n "Starting ${NAME} in ${ENVIRONMENT} mode: "
    cd ${DIRECTORY}
    RETVAL="`start-stop-daemon --quiet --start --oknodo --chdir ${DIRECTORY} --pidfile ${PIDFILE} --exec ${DAEMON} -- ${SNORBY_OPTIONS}`"

    if [[ ${?} == 0 ]]; then
        echo "${!}" >${PIDFILE}
        success
        RAILS_ENV=${ENVIRONMENT} ${DAEMON} exec rails r "Snorby::Worker.start"
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
    start-stop-daemon --quiet --stop --remove-pidfile --quiet --oknodo --retry 30 --pidfile ${PIDFILE}

    if [[ ${?} == 0 ]]; then
        success
        RAILS_ENV=${ENVIRONMENT} ${DAEMON} exec rails r "Snorby::Worker.stop"
    else
        failure
    fi
}

check_root

rvm use ruby-1.9.3-p551 &>/dev/null 2>&1

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
