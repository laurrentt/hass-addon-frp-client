#!/usr/bin/env bashio
WAIT_PIDS=()
CONFIG_PATH='/share/frpc.toml'
DEFAULT_CONFIG_PATH='/frpc.toml'

function stop_frpc() {
    bashio::log.info "Shutdown frpc client"
    kill -15 "${WAIT_PIDS[@]}"
}

bashio::log.info "Copying configuration."
cp $DEFAULT_CONFIG_PATH $CONFIG_PATH
sed -i "s/server_addr = \"your_server_addr\"/server_addr = \"$(bashio::config 'serverAddr')\"/" $CONFIG_PATH
sed -i "s/server_port = 7000/server_port = $(bashio::config 'serverPort')/" $CONFIG_PATH
sed -i "s/token = \"123456789\"/token = \"$(bashio::config 'authToken')\"/" $CONFIG_PATH
sed -i "s/customDomains = [\"custom_domain\"]/customDomains = [\"$(bashio::config 'customDomain')\"]/" $CONFIG_PATH
sed -i "s/remote_port = \"443\"/remote_port = \"$(bashio::config 'remotePort')\"/" $CONFIG_PATH

bashio::log.info "Starting frp client"

cat $CONFIG_PATH

cd /usr/src
./frpc -c $CONFIG_PATH & WAIT_PIDS+=($!)

tail -f /share/frpc.log &

trap "stop_frpc" SIGTERM SIGHUP
wait "${WAIT_PIDS[@]}"
