#!/usr/bin/env bash
# The CI gates for the examples monorepo, runnable locally — the same checks
# .github/workflows/build.yml runs (it checks out submodules + installs the
# toolchain / Vulkan ICD, then calls this with the matching command).
#   ./scripts/ci.sh              # fmt + build (event-logger + clear-color)
#   ./scripts/ci.sh decoupling   # nm: platform-only binary pulls none of our vulkan stack
#   ./scripts/ci.sh integration  # cross-lib test, delegated to zGameLib (auto-xvfb if headless)
#   ./scripts/ci.sh opengl       # OpenGL hand-off test, delegated to zGameLib (auto-xvfb if headless)
# The two cross-lib tests live INSIDE zGameLib (libs/zGameLib) — this repo only
# builds the example rungs, so integration/opengl delegate into the submodule.
# Needs the zGameLib submodule (and its nested adapters) checked out under libs/.
set -uo pipefail
cd "$(dirname "$0")/.."

zgame=libs/zGameLib

case "${1:-check}" in
  check)
    echo "== zig fmt --check =="; zig fmt --check build.zig build.zig.zon examples || exit 1
    echo "== zig build (event-logger + clear-color) =="; zig build || exit 1
    ;;
  decoupling)
    zig build || exit 1
    # The decoupling invariant: a platform-only binary pulls in none of OUR
    # vulkan stack. We match vulkan-zig's `vk.`-namespaced wrappers + volk/VMA/
    # shaderc symbols — NOT a bare `vk*` grep, which would also flag SDL3's own
    # bundled Vulkan loader (SDL_Vulkan_CreateSurface & its vk* table), part of
    # the platform backend and present in every SDL3-linked binary.
    echo "== nm: event-logger (platform-only) pulls none of our vulkan stack =="
    if nm zig-out/bin/event-logger | grep -E 'vk\.[A-Za-z]|volk[A-Z]|[Vv]ma[A-Z]|shaderc_[a-z]'; then
      echo "::error::our vulkan stack (vulkan-zig/volk/VMA) leaked into the platform-only binary"
      exit 1
    fi
    echo "clean — no vulkan-stack symbols in event-logger (SDL3's own vk loader is expected & ignored)"
    ;;
  integration)
    # Cross-lib integration test — lives in zGameLib. Needs a display + a Vulkan
    # loader. Headless (no DISPLAY): wrap in xvfb-run.
    if [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
      echo "== xvfb-run zig build (in $zgame) test-integration -Dshaderc =="
      ( cd "$zgame" && xvfb-run -a zig build test-integration -Dshaderc ) || exit 1
    else
      echo "== zig build (in $zgame) test-integration -Dshaderc =="
      ( cd "$zgame" && zig build test-integration -Dshaderc ) || exit 1
    fi
    ;;
  opengl)
    # OpenGL hand-off test — lives in zGameLib (GL is system-linked there). Needs
    # a display + a GL driver. Headless: xvfb-run + Mesa llvmpipe (software GL).
    if [ -z "${DISPLAY:-}" ] && command -v xvfb-run >/dev/null 2>&1; then
      echo "== xvfb-run zig build (in $zgame) test-opengl =="
      ( cd "$zgame" && LIBGL_ALWAYS_SOFTWARE=1 xvfb-run -a zig build test-opengl ) || exit 1
    else
      echo "== zig build (in $zgame) test-opengl =="
      ( cd "$zgame" && zig build test-opengl ) || exit 1
    fi
    ;;
  *)
    echo "unknown command: $1 (try: check | decoupling | integration | opengl)" >&2
    exit 2
    ;;
esac
echo "ok: ${1:-check}"
