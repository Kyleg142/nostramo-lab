#!/usr/bin/env bash

# Launches a privileged pod for low-level debugging. See the README for more info.

# Has to be hostname, not physical IP
node="$1"

# Defaults to Arch if no second arg is provided
image="${2:-archlinux:latest}"

if [ -z "$node" ]; then
    echo "Usage: debugger <node-name> [image]"
    echo "Example: debugger talos-worker-01"
    return 1
fi

echo "Launching privileged '$image' pod on node: $node..."

kubectl run debug-$(date +%s) \
    -n debug \
    --image="$image" \
    --restart=Never \
    --rm -it \
    --overrides='{
        "spec": {
            "nodeName": "'"$node"'",
            "hostPID": true,
            "hostNetwork": true,
            "containers": [{
                "name": "debug",
                "image": "'"$image"'",
                "command": ["/bin/bash"],
                "stdin": true,
                "tty": true,
                "securityContext": {
                    "privileged": true
                },
                "volumeMounts": [{
                    "name": "host-fs",
                    "mountPath": "/host"
                }]
            }],
            "volumes": [{
                "name": "host-fs",
                "hostPath": {
                    "path": "/"
                }
            }]
        }
    }'
