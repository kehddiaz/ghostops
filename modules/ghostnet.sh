#!/usr/bin/env bash
# ==========================================
# ghostnet.sh — v1.7 forensic-complete (adaptive + iwctl)
# Modular network identity rotation with audit-safe JSONL logging
# ==========================================

set -euo pipefail

# --- CONFIG ---
LOG_DIR="${HOME}/ghostops/logs"
LOG_FILE="${LOG_DIR}/ghostnet.log"
mkdir -p "$LOG_DIR"

# --- HELPERS ---
timestamp() { date -u +"%Y-%m-%dT%H:%M:%S%3NZ"; }

log_json() {
    local level="$1" event="$2" message="$3" note="${4:-}" extra="${5:-}"
    {
        echo -n "{\"timestamp\":\"$(timestamp)\",\"level\":\"${level}\",\"event\":\"${event}\",\"message\":\"${message}\""
        [[ -n "$note" ]] && echo -n ",\"note\":\"${note}\""
        [[ -n "$extra" ]] && echo -n ",${extra}"
        echo "}"
    } >> "$LOG_FILE"
}

have() { command -v "$1" >/dev/null 2>&1; }

random_local_mac() {
    # 02 = locally administered, unicast
    printf '02:%02x:%02x:%02x:%02x:%02x\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256))
}

get_iface_info() {
    local iface="$1"
    local mac ip gw dns ssid bssid conn_name
    mac=$(cat /sys/class/net/"$iface"/address 2>/dev/null || echo "unknown")
    ip=$(ip -4 addr show "$iface" | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
    gw=$(ip route | awk -v d="$iface" '$1=="default" && $5==d {print $3; exit}')
    dns=$(grep -E "^nameserver" /etc/resolv.conf 2>/dev/null | awk '{print $2}' | paste -sd "," -)
    ssid=$(iwgetid -r 2>/dev/null || echo "none")
    bssid=$(iw dev "$iface" link 2>/dev/null | awk '/Connected/ {print $3}')
    conn_name=$( (have nmcli && nmcli -t -f NAME,DEVICE connection show --active | grep ":$iface" | cut -d: -f1) || echo "none")
    echo "\"iface\":\"$iface\",\"mac\":\"$mac\",\"ip\":\"$ip\",\"gateway\":\"$gw\",\"dns\":\"$dns\",\"ssid\":\"$ssid\",\"bssid\":\"$bssid\",\"conn_name\":\"$conn_name\""
}

verify_connectivity() {
    local host="$1" timeout="$2"
    if ping -n -c1 -W"$timeout" "$host" &>/dev/null; then
        echo "\"verify_status\":\"ok\""
    else
        echo "\"verify_status\":\"fail\""
    fi
}

rand_host_octet() { awk -v s="$RANDOM" 'BEGIN{srand(s); print 20+int(rand()*201)}'; }

subnet_prefix() { echo "$1" | awk -F/ '{print $1}' | awk -F. '{print $1"."$2"."$3}'; }
subnet_prefixlen() { echo "$1" | awk -F/ '{print $2}'; }

# --- ARG PARSE ---
IFACE=""
MODE=""
SUBNET=""
GATEWAY=""
VERIFY_AFTER=0
VERIFY_HOST=""
LOG_NOTE=""
DRYRUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --iface) IFACE="$2"; shift 2 ;;
        --dhcp) MODE="dhcp"; shift ;;
        --static) MODE="static"; shift ;;
        --subnet) SUBNET="$2"; shift 2 ;;
        --gateway) GATEWAY="$2"; shift 2 ;;
        --verify-after) VERIFY_AFTER="$2"; shift 2 ;;
        --verify-host) VERIFY_HOST="$2"; shift 2 ;;
        --log-note) LOG_NOTE="$2"; shift 2 ;;
        --dry-run) DRYRUN=1; shift ;;
        -h|--help)
            cat <<USG
Usage: $0 --iface <name> (--dhcp | --static --subnet CIDR --gateway IP) [options]
Options:
  --verify-after <sec>   Wait N seconds then ping VERIFY_HOST
  --verify-host <host>   Host/IP to ping for verify
  --log-note <text>      Annotation for this run
  --dry-run              Log actions without applying
USG
            exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

[[ -z "$IFACE" ]] && { echo "Error: --iface required"; exit 1; }
[[ -z "$MODE" ]] && { echo "Error: --dhcp or --static required"; exit 1; }
if [[ "$MODE" == "static" ]]; then
    [[ -z "$SUBNET" || -z "$GATEWAY" ]] && { echo "Static mode requires --subnet and --gateway"; exit 1; }
fi

# --- START ---
START_TIME=$(date +%s)
OLD_INFO=$(get_iface_info "$IFACE")
log_json "info" "cycle_start" "ghostnet cycle start" "$LOG_NOTE" "$OLD_INFO"

if [[ "$DRYRUN" -eq 0 ]]; then
    # Spoof MAC
    ip link set "$IFACE" down || true
    if have macchanger; then
        macchanger -r "$IFACE" >/dev/null || true
    else
        NEWMAC="$(random_local_mac)"
        ip link set "$IFACE" address "$NEWMAC" || true
    fi
    ip link set "$IFACE" up || true

    # Assign IP (DHCP or static), with adaptive DHCP renewal
    if [[ "$MODE" == "dhcp" ]]; then
        ip addr flush dev "$IFACE" || true
        if have dhclient; then
            dhclient -r "$IFACE" || true
            dhclient "$IFACE" || true
        elif have nmcli; then
            nmcli dev disconnect "$IFACE" || true
            nmcli dev connect "$IFACE" || true
        elif have iwctl; then
            # Try to reconnect using iwctl to the same SSID (if known)
            CUR_SSID=$(iwgetid -r 2>/dev/null || true)
            iwctl station "$IFACE" disconnect || true
            if [[ -n "${CUR_SSID:-}" ]]; then
                iwctl station "$IFACE" connect "$CUR_SSID" || true
            else
                # As a fallback, just cycle the link and rely on system DHCP
                ip link set "$IFACE" down || true
                sleep 1
                ip link set "$IFACE" up || true
            fi
        else
            # Last resort: link reset; rely on system DHCP agent if any
            ip link set "$IFACE" down || true
            sleep 1
            ip link set "$IFACE" up || true
        fi
    else
        # Static assignment
        PREF="$(subnet_prefix "$SUBNET")"
        PFXLEN="$(subnet_prefixlen "$SUBNET")"
        HOST="$(rand_host_octet)"
        NEW_IP="${PREF}.${HOST}"
        ip addr flush dev "$IFACE" || true
        ip addr add "$NEW_IP/$PFXLEN" dev "$IFACE" || true
        ip route replace default via "$GATEWAY" dev "$IFACE" || true
    fi
fi

# --- VERIFY ---
if (( VERIFY_AFTER > 0 )); then
    sleep "$VERIFY_AFTER"
fi

NEW_INFO=$(get_iface_info "$IFACE")
VERIFY_INFO=""
[[ -n "${VERIFY_HOST:-}" ]] && VERIFY_INFO=$(verify_connectivity "$VERIFY_HOST" 2)

END_TIME=$(date +%s)
RUN_TIME=$((END_TIME - START_TIME))

OLD_MAC=$(echo "$OLD_INFO" | grep -Eo '"mac":"[^"]*"' | cut -d: -f2- | tr -d '"')
OLD_IP=$(echo "$OLD_INFO" | grep -Eo '"ip":"[^"]*"' | cut -d: -f2- | tr -d '"')

EXTRA="${NEW_INFO},\"old_mac\":\"${OLD_MAC}\",\"old_ip\":\"${OLD_IP}\",\"mode\":\"${MODE}\",\"dryrun\":${DRYRUN},\"run_time_sec\":${RUN_TIME}"
[[ -n "$VERIFY_INFO" ]] && EXTRA="${EXTRA},${VERIFY_INFO}"

log_json "info" "cycle_complete" "ghostnet cycle complete" "$LOG_NOTE" "$EXTRA"







