#!/usr/bin/env python3
"""VulnScan - Consumes CAM-SEC JSON output"""
import json, os, sys
from pathlib import Path

JSON_DIR = os.path.expanduser("~/.camsec/json_output")

def load_latest_report(ip: str) -> dict:
    """Load the most recent JSON report for an IP"""
    pattern = f"full_report_{ip.replace('.', '_')}_*.json"
    files = sorted(Path(JSON_DIR).glob(pattern))
    if not files:
        return {}
    with open(files[-1]) as f:
        return json.load(f)

def process_shodan_results():
    """Process Shodan search results"""
    files = sorted(Path(JSON_DIR).glob("shodan_*.json"))
    if not files:
        print("[!] No Shodan results found")
        return
    
    with open(files[-1]) as f:
        data = json.load(f)
    
    print(f"[+] Processing {len(data['results'])} Shodan results")
    for result in data['results']:
        ip = result['ip']
        if result.get('vulnerabilities'):
            print(f"  [!] {ip}:{result['port']} - {len(result['vulnerabilities'])} CVEs")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        report = load_latest_report(sys.argv[1])
        print(json.dumps(report, indent=2))
    else:
        process_shodan_results()
