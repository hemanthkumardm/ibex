#!/usr/bin/env bash
# OpenROAD Studio Container Execution Helper
set -euo pipefail
IMG="${OPENROAD_IMAGE:-efabless/openlane:v0.9}"
echo "Using image $IMG — mounting $(pwd) as /work"
docker run --rm -v "$(pwd):/work" -w /work "$IMG" bash -lc 'scripts/run_pipeline.sh'
