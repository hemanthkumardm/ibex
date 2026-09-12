#!/usr/bin/env bash
# =====================================================================
# Ace-Seek OpenROAD Studio — Container Execution Helper
# =====================================================================
# Runs individual stages or full flow inside OpenLane container
# Usage:
#   ./docker-run.sh              (runs full pipeline)
#   ./docker-run.sh placement    (runs placement stage only)
#   ./docker-run.sh sta-pvt      (runs multi-corner STA)
# =====================================================================
set -euo pipefail

IMG="${OPENROAD_IMAGE:-efabless/openlane:v0.9}"
TARGET="${1:-all}"

echo "====================================================================="
echo "ACE-SEEK OPENROAD STUDIO :: CONTAINER RUNNER"
echo "Target Command: $TARGET"
echo "Container:      $IMG"
echo "Workdir:        $(pwd)"
echo "====================================================================="

if [ "$TARGET" = "all" ] || [ "$TARGET" = "pipeline" ]; then
  docker run --rm -v "$(pwd):/work" -w /work "$IMG" bash -lc 'scripts/run_pipeline.sh'
elif [ "$TARGET" = "synth" ]; then
  docker run --rm -v "$(pwd):/work" -w /work "$IMG" bash -lc 'yosys -c scripts/synth.ys'
elif [ "$TARGET" = "sta-pvt" ]; then
  docker run --rm -v "$(pwd):/work" -w /work "$IMG" bash -lc 'sta -exit scripts/opensta.tcl'
else
  # Pass stage to openroad coordinator
  docker run --rm -v "$(pwd):/work" -w /work "$IMG" bash -lc "STAGE=$TARGET openroad -exit scripts/openroad.tcl"
fi
