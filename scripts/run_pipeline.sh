#!/usr/bin/env bash
# ==============================================================================
# OpenROAD/OpenLane Cloud Pipeline Runner for Ibex RISC-V Core (SkyWater 130nm)
# ==============================================================================
# This script submits the Ibex synthesizable core and timing constraints to an
# OpenLane runner endpoint, streams execution logs, and retrieves signoff
# deliverables (GDSII, DEF, SPEF, STA/DRC/LVS reports).
#
# Usage:
#   export OPENROAD_RUNNER_URL="http://your-runner-host:port"
#   export OPENROAD_API_KEY="your-api-key"
#   ./scripts/run_pipeline.sh
# ==============================================================================

set -euo pipefail

RUNNER_URL="${OPENROAD_RUNNER_URL:-http://localhost:3000}"
API_KEY="${OPENROAD_API_KEY:-ace_max_usr_test_123}"
OWNER_ID="${OPENROAD_OWNER_ID:-ibex_prod_tapeout}"
# untilStage: synthesis | floorplan | placement | cts | routing | gds | all
UNTIL_STAGE="${OPENROAD_UNTIL_STAGE:-all}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL_FILE="$REPO_ROOT/rtl/ibex_core.v"
SDC_FILE="$REPO_ROOT/config/constraints.sdc"
OUTPUT_DIR="$REPO_ROOT/outputs"
REPORTS_DIR="$REPO_ROOT/reports"
LOGS_DIR="$REPO_ROOT/logs"

mkdir -p "$OUTPUT_DIR" "$REPORTS_DIR" "$LOGS_DIR"

if [[ ! -f "$RTL_FILE" ]]; then
  echo "[-] Error: Synthesizable RTL not found at $RTL_FILE" >&2
  exit 1
fi

if [[ ! -f "$SDC_FILE" ]]; then
  echo "[-] Error: Timing constraints not found at $SDC_FILE" >&2
  exit 1
fi

echo "=================================================================="
echo " Starting Ibex RISC-V OpenLane Pipeline on SkyWater 130nm"
echo " Target Runner: $RUNNER_URL"
echo " RTL File     : $RTL_FILE ($(wc -l < "$RTL_FILE") lines)"
echo " SDC File     : $SDC_FILE"
echo "=================================================================="

python3 -u - <<PYTHON_SCRIPT
import json
import os
import sys
import time
import urllib.request
import urllib.error

runner_url = os.environ.get("RUNNER_URL", "http://localhost:3000").rstrip("/")
# Map HTTP status to a readable error instead of a bare traceback

def http_error_body(e):
    try:
        return e.read().decode()
    except Exception:
        return ""
api_key = os.environ.get("API_KEY", "")
owner_id = os.environ.get("OWNER_ID", "ibex_prod_tapeout")
rtl_file = "$RTL_FILE"
sdc_file = "$SDC_FILE"
output_dir = "$OUTPUT_DIR"
reports_dir = "$REPORTS_DIR"
logs_dir = "$LOGS_DIR"

with open(rtl_file, "r") as f:
    rtl_content = f.read()

with open(sdc_file, "r") as f:
    sdc_content = f.read()

payload = {
    "mode": "container",
    "untilStage": "$UNTIL_STAGE",
    "openlaneConfig": {
        "CLOCK_PORT": "clk_i",
        "CLOCK_NET": "clk_i",
        "CLOCK_PERIOD": 15.0,
        "SYNTH_STRATEGY": "AREA 0",
        "FP_SIZING": "relative",
        "FP_CORE_UTIL": 40,
        "FP_ASPECT_RATIO": 1,
        "FP_CORE_MARGIN": 20,
        "PL_TARGET_DENSITY": 0.45,
        "CELL_PAD": 4,
        "GLB_RESIZER_TIMING_OPTIMIZATIONS": 1,
        "PL_RESIZER_TIMING_OPTIMIZATIONS": 1,
        "GLB_RESIZER_HOLD_SLACK_MARGIN": 0.1,
        "PL_RESIZER_HOLD_SLACK_MARGIN": 0.1,
        "DIODE_INSERTION_STRATEGY": 3
    },
    "project": {
        "projectName": "ibex-sky130",
        "designName": "ibex_core",
        "topModule": "ibex_core",
        "pdk": "sky130",
        "files": [
            {"name": "ibex_core.v", "content": rtl_content, "role": "rtl", "size": len(rtl_content), "uploadedAt": "2026-09-12T00:00:00Z"},
            {"name": "constraints.sdc", "content": sdc_content, "role": "sdc", "size": len(sdc_content), "uploadedAt": "2026-09-12T00:00:00Z"}
        ],
        "updatedAt": "2026-09-12T00:00:00Z"
    }
}

headers = {
    "Content-Type": "application/json",
    "x-api-key": api_key,
    "x-openroad-owner": owner_id
}

print(f"[*] Submitting Ibex tapeout job to {runner_url}/api/openroad/run ...")
req = urllib.request.Request(f"{runner_url}/api/openroad/run", data=json.dumps(payload).encode(), headers=headers)
try:
    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read().decode())
except urllib.error.HTTPError as e:
    print(f"[-] HTTP Error {e.code}: {http_error_body(e)}")
    sys.exit(1)

job_id = res["result"]["jobId"]
print(f"[+] Job successfully submitted! Job ID: {job_id}")

last_log_len = 0
start_time = time.time()

while True:
    time.sleep(5)
    elapsed = int(time.time() - start_time)
    p_req = urllib.request.Request(f"{runner_url}/api/openroad/jobs/{job_id}", headers=headers)
    try:
        with urllib.request.urlopen(p_req) as resp:
            data = json.loads(resp.read().decode())["result"]
    except urllib.error.HTTPError as e:
        print(f"[-] Polling error {e.code}: {http_error_body(e)[:300]}")
        continue

    status = data.get("status")
    message = data.get("message", "")
    log = data.get("log", "")
    
    if len(log) > last_log_len:
        new_lines = log[last_log_len:].strip().splitlines()
        for line in new_lines[-5:]:
            print(f"[{elapsed}s] {line}")
        last_log_len = len(log)
    else:
        print(f"[{elapsed}s] Status: {status} | {message}")

    if status in ("succeeded", "failed"):
        print(f"\n[+] Pipeline finished with status: {status.upper()} in {elapsed}s")
        log_file = os.path.join(logs_dir, f"{job_id}.log")
        with open(log_file, "w") as lf:
            lf.write(log)
        print(f"[+] Execution log saved to {log_file}")

        artifacts = data.get("artifacts", [])
        print(f"[+] Downloading {len(artifacts)} artifacts...")
        for art in artifacts:
            art_name = art.get("name")
            if not art_name:
                continue
            art_url = f"{runner_url}/api/openroad/jobs/{job_id}?download={urllib.request.quote(art_name)}"
            dl_req = urllib.request.Request(art_url, headers=headers)
            dest_dir = output_dir if any(art_name.endswith(ext) for ext in [".gds", ".def", ".spef", ".v", ".sdc"]) else reports_dir
            dest_path = os.path.join(dest_dir, art_name)
            try:
                with urllib.request.urlopen(dl_req) as dl_resp, open(dest_path, "wb") as out_f:
                    out_f.write(dl_resp.read())
                print(f"    - Saved {art_name} -> {dest_path}")
            except Exception as ex:
                print(f"    ! Failed to download {art_name}: {ex}")

        if status == "failed":
            sys.exit(1)
        break
PYTHON_SCRIPT

chmod +x "$REPO_ROOT/scripts/run_pipeline.sh"
echo "[+] Pipeline execution completed."
