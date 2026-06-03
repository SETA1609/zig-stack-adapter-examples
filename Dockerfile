# Reproducible dev/test container for the examples monorepo (both adapters).
#
# Build from a checkout WITH submodules (`git submodule update --init --recursive`):
#   docker build -t stack-examples .
#   docker run --rm stack-examples                                 # fmt + build (event-logger + clear-color)
#   docker run --rm stack-examples bash scripts/ci.sh decoupling   # nm: platform-only binary has no Vulkan
#   docker run --rm stack-examples bash scripts/ci.sh integration  # cross-lib test (auto-xvfb + lavapipe)
#
# Carries both halves' runtime needs: X11/Wayland libs + xvfb (the platform side
# opens a window) and lavapipe + libvulkan (the vulkan side, software ICD — no
# GPU). SDL3 and the Vulkan headers are vendored/fetched by Zig, so no -dev
# packages. First `zig build` fetches the pinned deps (network).
FROM ubuntu:24.04
ARG ZIG_VERSION=0.16.0
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl xz-utils git python3 python3-pip \
      mesa-vulkan-drivers libvulkan1 vulkan-tools \
      xvfb \
      libx11-6 libxext6 libxrandr2 libxi6 libxcursor1 libxfixes3 \
      libxkbcommon0 libwayland-client0 libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Zig, pinned — URL resolved from the official release index.
RUN set -eux; \
    url="$(curl -fsSL https://ziglang.org/download/index.json \
      | python3 -c "import sys,json;print(json.load(sys.stdin)['${ZIG_VERSION}']['x86_64-linux']['tarball'])")"; \
    curl -fsSL "$url" -o /tmp/zig.tar.xz; \
    mkdir -p /opt/zig; tar -xJf /tmp/zig.tar.xz -C /opt/zig --strip-components=1; \
    ln -s /opt/zig/zig /usr/local/bin/zig; rm /tmp/zig.tar.xz; zig version

# lavapipe is the sole ICD → the integration stack runs headless, no GPU.
ENV VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json

WORKDIR /work
COPY . .
RUN python3 -m pip install --break-system-packages --quiet pyyaml || true

CMD ["bash", "scripts/ci.sh", "check"]
