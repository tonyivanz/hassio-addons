#!/usr/bin/with-contenv bashio

# --- CONSTANTS ---
PERSISTENT_KEY="/data/id_ed25519"
PERSISTENT_PUB="${PERSISTENT_KEY}.pub"

# --- 1. KEY GENERATION ---
if [ ! -f "$PERSISTENT_KEY" ]; then
    bashio::log.info "No persistent key found. Generating new SSH key pair..."
    ssh-keygen -b 4096 -t ed25519 -f "$PERSISTENT_KEY" -N "" -C "homeassistant-autossh"
    chmod 600 "$PERSISTENT_KEY"
    bashio::log.info "New key generated successfully."
else
    bashio::log.info "Persistent key found."
fi

# --- 2. PRINT PUBLIC KEY ---
# This prints the key to the Add-on logs so the user can copy it
echo " "
echo "========================================================================"
echo "                       YOUR PUBLIC SSH KEY"
echo "Copy the line below to ~/.ssh/authorized_keys on your remote server(s):"
echo "------------------------------------------------------------------------"
cat "$PERSISTENT_PUB"
echo "------------------------------------------------------------------------"
echo "========================================================================"
echo " "

# Ensure .ssh directory exists for root (required for known_hosts)
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# --- 3. TUNNEL SETUP FUNCTION ---
setup_tunnel() {
    local host=$1
    local user=$2
    local port=$3
    local mon_port=$4
    local tunnel_args=$5
    local extra=$6

    echo "--- Configuring Connection: $user@$host ---"

    # Auto-accept host key to prevent interactive prompt hanging
    ssh-keyscan -p "$port" -H "$host" >> /root/.ssh/known_hosts 2>/dev/null

    echo "Starting autossh instance..."
    
    # -M: Monitoring port
    # -N: Do not execute remote command
    # -i: Identity file (our persistent key)
    # -o StrictHostKeyChecking=no: Automatically add new host keys
    
    autossh -M "$mon_port" \
        -o "ServerAliveInterval 30" \
        -o "ServerAliveCountMax 3" \
        -o "ExitOnForwardFailure yes" \
        -o "StrictHostKeyChecking no" \
        -N \
        -p "$port" \
        -i "$PERSISTENT_KEY" \
        $tunnel_args \
        $extra \
        "$user@$host" &
        
    local pid=$!
    bashio::log.info "Tunnel started for $host (PID $pid) with args: $tunnel_args"
}

# --- 4. MAIN LOOP ---
count=$(bashio::config 'connections | length')

if [ "$count" -eq 0 ]; then
    bashio::log.warning "No connections defined in configuration."
else
    for (( i=0; i<count; i++ )); do
        HOST=$(bashio::config "connections[$i].host")
        USER=$(bashio::config "connections[$i].user")
        PORT=$(bashio::config "connections[$i].port")
        MON_PORT=$(bashio::config "connections[$i].monitor_port")
        TUNNEL_ARGS=$(bashio::config "connections[$i].tunnel_args")
        EXTRA=$(bashio::config "connections[$i].extra_args")

        # Set Defaults
        if [ -z "$MON_PORT" ] || [ "$MON_PORT" == "null" ]; then MON_PORT=0; fi
        if [ -z "$PORT" ] || [ "$PORT" == "null" ]; then PORT=22; fi

        setup_tunnel "$HOST" "$USER" "$PORT" "$MON_PORT" "$TUNNEL_ARGS" "$EXTRA"
    done
fi

echo "All connections initialized. Entering keep-alive loop..."

# Wait keeps the script running while child processes (autossh) are active
wait