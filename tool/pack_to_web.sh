#!/usr/bin/env bash
# Copies a GymZ media pack folder next to the web build so the pack can be
# tried on localhost (MediaPack's web test mode). Run after `flutter build web`.
# Usage: tool/pack_to_web.sh [pack folder]   (default: ~/Desktop/GymZ-pack)
set -euo pipefail
src="${1:-$HOME/Desktop/GymZ-pack}"
dest="build/web/assets/gymz_pack"
rm -rf "$dest"
mkdir -p "$dest"
names=()
for f in "$src"/*; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"
  case "$name" in *.txt|*.md) continue ;; esac
  cp "$f" "$dest/$name"
  names+=("\"$name\"")
done
(IFS=,; echo "[${names[*]}]") > "$dest/index.json"
echo "${#names[@]} archivos copiados a $dest"
