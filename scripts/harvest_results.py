#!/usr/bin/env python3
import json
import os
import re
import sys
import urllib.request
import urllib.parse

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
OUTPUTS_DIR = os.path.join(REPO_ROOT, "outputs")
REPORTS_DIR = os.path.join(REPO_ROOT, "reports")
LOGS_DIR = os.path.join(REPO_ROOT, "logs")

RUNNER_URL = os.environ.get("OPENROAD_RUNNER_URL", "http://3.90.62.206").rstrip("/")
API_KEY = os.environ.get("OPENROAD_API_KEY", "ace_max_usr_test_123")
OWNER_ID = os.environ.get("OPENROAD_OWNER_ID", "ibex_tapeout_run_1")
JOB_ID = os.environ.get("JOB_ID", "ol_ibex_core_ibex_core_mty98xin")

headers = {
    "x-api-key": API_KEY,
    "x-openroad-owner": OWNER_ID
}

print(f"[*] Querying Job {JOB_ID} on {RUNNER_URL}...")
req = urllib.request.Request(f"{RUNNER_URL}/api/openroad/jobs/{JOB_ID}", headers=headers)
with urllib.request.urlopen(req) as resp:
    res = json.loads(resp.read().decode())["result"]

status = res.get("status")
message = res.get("message", "")
log = res.get("log", "")
artifacts = res.get("artifacts", [])

print(f"[+] Status: {status.upper()} | {message}")
print(f"[+] Artifacts count: {len(artifacts)}")

# Save run log
log_path = os.path.join(LOGS_DIR, f"{JOB_ID}.log")
with open(log_path, "w") as f:
    f.write(log)
print(f"[+] Saved execution log to {log_path}")

# Download all artifacts
downloaded = []
for art in artifacts:
    name = art.get("name")
    if not name:
        continue
    url = f"{RUNNER_URL}/api/openroad/jobs/{JOB_ID}?download={urllib.parse.quote(name)}"
    dl_req = urllib.request.Request(url, headers=headers)
    
    # Sort into outputs or reports
    if any(name.endswith(ext) for ext in [".gds", ".gds.gz", ".def", ".spef", ".v", ".sdc"]):
        dest = os.path.join(OUTPUTS_DIR, name)
    elif "synthesis" in name:
        dest = os.path.join(REPORTS_DIR, "01_synthesis", name)
    elif "floorplan" in name:
        dest = os.path.join(REPORTS_DIR, "02_floorplan", name)
    elif "placement" in name:
        dest = os.path.join(REPORTS_DIR, "03_placement", name)
    elif "cts" in name:
        dest = os.path.join(REPORTS_DIR, "04_cts", name)
    elif "routing" in name:
        dest = os.path.join(REPORTS_DIR, "05_routing", name)
    else:
        dest = os.path.join(REPORTS_DIR, "06_signoff", name)
        
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    try:
        with urllib.request.urlopen(dl_req) as r, open(dest, "wb") as out:
            out.write(r.read())
        downloaded.append((name, dest))
        print(f"    - Downloaded {name} -> {os.path.relpath(dest, REPO_ROOT)}")
    except Exception as e:
        print(f"    ! Error downloading {name}: {e}")

print(f"[+] Download complete: {len(downloaded)} files harvested.")
