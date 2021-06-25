#!/usr/bin/env bash
set -o errexit

podman run --rm --name test-container -dt -p 2222:22 localhost/gcc-ssh
sleep 5
nc -z localhost 22

podman stop test-container
