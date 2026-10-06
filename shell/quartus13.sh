#!/bin/bash

QUARTUS13_IMAGE=${QUARTUS13_IMAGE:-"quartus:13.0.1.2"}
LICENSE_MAC=${LICENSE_MAC:-"00:FF:FF:FF:FF:FF"}
LM_LICENSE_FILE=${LM_LICENSE_FILE:-"$HOME/.Altera/quartus.dat"}
MGLS_LICENSE_FILE=${MGLS_LICENSE_FILE:-"$HOME/.Altera/modelsim.dat"}

QUARTUS_PATH=/opt/altera/13.0sp1/quartus/linux64

# Container engine: docker or podman. Autodetected unless CONTAINER_ENGINE is set.
if [ -z "$CONTAINER_ENGINE" ]; then
    if command -v docker >/dev/null 2>&1 && ! docker --version 2>/dev/null | grep -qi podman \
        && docker info >/dev/null 2>&1; then
        CONTAINER_ENGINE=docker
    elif command -v podman >/dev/null 2>&1; then
        CONTAINER_ENGINE=podman
    else
        echo "Error: neither a working docker nor podman was found" >&2
        exit 1
    fi
fi

if [ "$CONTAINER_ENGINE" = "podman" ]; then
    # Rootless podman maps container root to the host user, so files created in
    # $HOME keep the user's ownership. Avoids --userns=keep-id, which copies and
    # chowns the whole image on first run.
    # --mac-address needs a bridge network (rootless default is pasta/slirp4netns).
    ENGINE_ARGS=(
        -e "HOME=$HOME"
        --network bridge
    )
else
    ENGINE_ARGS=(
        --user $(id -u):$(id -g)
        -v /etc/passwd:/etc/passwd:ro
        -v /etc/group:/etc/group:ro
        --device-cgroup-rule='c *:* rmw'
    )
fi

# X11 cookie (e.g. Xwayland keeps it outside $HOME, under /run/user)
if [ -n "$XAUTHORITY" ] && [ -f "$XAUTHORITY" ]; then
    ENGINE_ARGS+=(-e "XAUTHORITY=$XAUTHORITY" -v "$XAUTHORITY:$XAUTHORITY:ro")
fi

$CONTAINER_ENGINE run --rm \
"${ENGINE_ARGS[@]}" \
-e DISPLAY \
-e PATH=/bin:/sbin:$QUARTUS_PATH \
-e LD_LIBRARY_PATH=$QUARTUS_PATH \
-e "LM_LICENSE_FILE=$LM_LICENSE_FILE" \
-e "MGLS_LICENSE_FILE=$MGLS_LICENSE_FILE" \
--mac-address=$LICENSE_MAC \
-v /tmp/.X11-unix:/tmp/.X11-unix \
-v "$HOME:$HOME" \
-w "$PWD" \
--ipc=host \
-v /dev/bus/usb:/dev/bus/usb \
--security-opt seccomp=unconfined \
-ti $QUARTUS13_IMAGE "$@"
