#!/usr/bin/env bash
set -e
echo "Waiting for emulator to boot..."
adb wait-for-device
BOOT_COMPLETE=""
until [[ "$BOOT_COMPLETE" == "1" ]]; do
  BOOT_COMPLETE=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r') || BOOT_COMPLETE=""
  echo "boot_complete=$BOOT_COMPLETE"
  sleep 1
done
echo "Emulator booted."
