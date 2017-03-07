#!/bin/bash
set -e

function header {
    STR=$(echo "$1" | awk '{print toupper($0)}')
    STR_LEN=${#STR}
    MAX_LEN="50"
    HEADER_LEN=$(expr $MAX_LEN - $STR_LEN - 6)
    DASHES=$(printf "%0.s-" $(seq 1 $HEADER_LEN))
    HEADER_STR="--| $STR |$DASHES"
    echo $HEADER_STR
}

function handle_signal {
    SIG=$1
    header "caught signal - running chef-server-ctl ${SIG}"
    chef-server-ctl $SIG
}

### fixes for anything required inside the volume mounted data dir

mkdir -p /var/opt/opscode/log


### start it up

header "starting runit"
/opt/opscode/embedded/bin/runsvdir-start &

### FIX ME > If hostname != /var/opt/container_id then reconfigure

header "reconfiguring chef server"
chef-server-ctl reconfigure

if [ "$ENABLE_CHEF_MANAGE" == "1" ]; then
    header "reconfiguring chef manage"
    chef-manage-ctl reconfigure
fi

hostname > /var/opt/container_id

### handle incoming signals

trap "{ handle_signal hup; }" HUP
trap "{ handle_signal stop; exit; }" SIGINT
trap "{ handle_signal stop; exit; }" SIGTERM
trap "{ handle_signal usr1; }" USR1
trap "{ handle_signal usr2; }" USR2


### long running process (logs all processes to STDOUT)

header "startup complete - now watching logs longterm"
chef-server-ctl tail
