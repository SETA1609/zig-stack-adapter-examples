#!/usr/bin/env bash
# The CI gates for the examples monorepo, runnable locally — the same checks
# .github/workflows/build.yml runs (it checks out submodules + installs the
# toolchain / Vulkan ICD, then calls this with the matching command).
#   ./scripts/ci.sh              # fmt + build (event-logger + clear-color)
#   ./scripts/ci.sh decoupling   # nm: platform-only binary has zero Vulkan symbols
#   ./scripts/ci.sh integration  # cross-lib test-integration -Dshaderc (auto-xvfb if headless)
# Needs the submodules under libs/ checked out.
set -uo pipefail
cd "$(dirname "$0")/.."

case "${1:-check}" in
  check)
    echo "== zig fmt --check =="; zig fmt --check build.zig build.zig.zon shared examples tests || exit 1
    echo "== zig build (event-logger + clear-color) =="; zig build || exit 1
    ;;
  decoupling)
    zig build || exit 1
    echo "== nm: event-logger (platform-only) has no Vulkan symbols =="
    if nm zig-out/bin/event-logger | grep -E 'vk[A-Z][A-Za-z]+|VK_[A-Z]'; then
      echo "::error::Vulkan symbols leaked into the platform-only binary"
      exit 1
    fi
    echo "clean — no vk*/VK_ symbols in event-logger"
    ;;
  integration)
    # Needs a display + a Vulkan loader. Headless (no DISPLAY): wrap in xvfb-run.
    if [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
      echo "== xvfb-run zig build test-integration -Dshaderc =="
      xvfb-run -a zig build test-integration -Dshaderc || exit 1
    else
      echo "== zig build test-integration -Dshaderc =="
      zig build test-integration -Dshaderc || exit 1
    fi
    ;;
  *)
    echo "unknown command: $1 (try: check | decoupling | integration)" >&2
    exit 2
    ;;
esac
echo "ok: ${1:-check}"
