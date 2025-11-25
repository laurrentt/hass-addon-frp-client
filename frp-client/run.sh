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
sed -i "s/custom_domains = \"custom_domain\"/custom_domains = \"$(bashio::config 'customDomain')\"/" $CONFIG_PATH
sed -i "s/local_port = \"8123\"/local_port = \"$(bashio::config 'homeAssistantPort')\"/" $CONFIG_PATH
sed -i "s/remote_port = \"443\"/remote_port = \"$(bashio::config 'remotePort')\"/" $CONFIG_PATH
sed -i "s/\[letsencryptvalidation\]/\[letsencryptvalidation$(bashio::config 'configurationSuffix')\]/" $CONFIG_PATH
sed -i "s/\[homeassistant\]/\[homeassistant$(bashio::config 'configurationSuffix')\]/" $CONFIG_PATH

# Add extra ports if configured
if bashio::config.has_value 'extraPorts'; then
    bashio::log.info "Adding extra ports configuration"
    for port in $(bashio::config 'extraPorts|keys'); do
        PORT_NUM=$(bashio::config "extraPorts[${port}].port")
        PORT_TYPE=$(bashio::config "extraPorts[${port}].type")
        SUFFIX=$(bashio::config 'configurationSuffix')
        
        bashio::log.info "Adding port ${PORT_NUM} with type ${PORT_TYPE}"
        
        cat >> $CONFIG_PATH << EOF

[homeassistant_extra_port_${PORT_NUM}${SUFFIX}]
type = "${PORT_TYPE}"
local_port = "${PORT_NUM}"
remote_port = "${PORT_NUM}"
custom_domains = "$(bashio::config 'customDomain')"
EOF
    done
fi

bashio::log.info "Starting frp client"

cat $CONFIG_PATH

cd /usr/src
./frpc -c $CONFIG_PATH & WAIT_PIDS+=($!)

tail -f /share/frpc.log &

trap "stop_frpc" SIGTERM SIGHUP
wait "${WAIT_PIDS[@]}"
