#!/bin/sh

echo "Starting WsTunnel Client Add-on..."

CONFIG_PATH=/data/options.json

if [ ! -f "$CONFIG_PATH" ]; then
    echo "Error: Configuration file not found at $CONFIG_PATH"
    exit 1
fi

SERVER_COUNT=$(jq '.servers | length' $CONFIG_PATH)

if [ "$SERVER_COUNT" = "null" ] || [ -z "$SERVER_COUNT" ] || [ "$SERVER_COUNT" -eq 0 ]; then
    echo "Error: No servers configured. Please check your Add-on settings."
    exit 1
fi

PIDS=""

# Handle shutdown smoothly
cleanup() {
    echo "Shutting down WsTunnel connections..."
    for pid in $PIDS; do
        kill -SIGTERM "$pid" 2>/dev/null || true
    done
    exit 0
}

trap cleanup TERM INT

i=0
while [ "$i" -lt "$SERVER_COUNT" ]; do
    URL=$(jq -r ".servers[$i].url" $CONFIG_PATH)
    
    # Extract the optional prefix. Using "// empty" ensures it returns nothing if left blank.
    PREFIX=$(jq -r ".servers[$i].upgrade_path_prefix // empty" $CONFIG_PATH)
    
    echo "Configuring tunnel for $URL..."
    
    EXTRA_ARGS=""
    if [ -n "$PREFIX" ] && [ "$PREFIX" != "null" ]; then
        echo "Using HTTP upgrade path prefix: $PREFIX"
        EXTRA_ARGS="--http-upgrade-path-prefix $PREFIX"
    fi
    
    # Extract multiple port forwards per server
    FORWARD_ARGS=""
    FWD_COUNT=$(jq ".servers[$i].forward | length" $CONFIG_PATH)
    
    j=0
    while [ "$j" -lt "$FWD_COUNT" ]; do
        FWD=$(jq -r ".servers[$i].forward[$j]" $CONFIG_PATH)
        
        # wstunnel v10+ requires protocol prefixes. Auto-apply tcp:// if missing.
        if ! echo "$FWD" | grep -qE "^(tcp|udp|stdio|socks5)://"; then
            FWD="tcp://$FWD"
        fi
        
        FORWARD_ARGS="$FORWARD_ARGS -R $FWD"
        j=$((j + 1))
    done
    
    # Spawn the wstunnel connection in a background auto-restart loop
    (
        while true; do
            echo "Connecting to $URL..."
            wstunnel client $FORWARD_ARGS $EXTRA_ARGS "$URL"
            EXIT_CODE=$?
            echo "Connection to $URL dropped (exit code $EXIT_CODE). Restarting in 5 seconds..."
            sleep 5
        done
    ) &
    
    # Track the subshell PID
    PIDS="$PIDS $!"
    
    i=$((i + 1))
done

echo "All tunnels initiated. Waiting for signals..."
wait