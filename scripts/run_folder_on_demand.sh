#!/bin/sh
# Map alias (MTX_PATH) -> folder under /videos using /opt/aliases/<alias>
# Build a concat playlist and stream it as a continuous channel.
# Try zero-CPU (-c copy) first; if that fails (mixed codecs/timestamps), fall back to a safe re-encode.

set -eu

NAME="${MTX_PATH:-}"
[ -n "$NAME" ] || { echo "MTX_PATH empty"; sleep 3; exit 1; }

# Resolve alias to target (folder or file)
TARGET=""
if [ -f "/opt/aliases/$NAME" ]; then
  TARGET="$(tr -d '\r\n' < "/opt/aliases/$NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
fi

DIR=""
FILE=""

if [ -n "$TARGET" ] && [ -d "/videos/${TARGET}" ]; then
  DIR="/videos/${TARGET}"
elif [ -n "$TARGET" ] && [ -f "/videos/${TARGET}" ]; then
  FILE="/videos/${TARGET}"
elif [ -d "/videos/${NAME}" ]; then
  DIR="/videos/${NAME}"
else
  CAND="$(ls -1t /videos/${NAME}.* 2>/dev/null | head -n1 || true)"
  [ -n "$CAND" ] && FILE="$CAND"
fi

OUT="rtsp://127.0.0.1:${RTSP_PORT}/${NAME}"

if [ -n "$DIR" ]; then
    PL="/tmp/playlist_${NAME}.txt"
    rm -f "$PL"

    # Build playlist robustly (handles spaces, quotes, upper/lowercase extensions)
    find "$DIR" -maxdepth 1 -type f \
  \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.avi' \) \
  -print0 \
    | sort -z \
    | while IFS= read -r -d '' f; do
    esc=$(printf "%s" "$f" | sed "s/'/'\\\\''/g")
    printf "file '%s'\n" "$esc" >> "$PL"
  done

if [ ! -s "$PL" ]; then
  echo "No video files in $DIR"; sleep 5; exit 1
fi



    ffmpeg -hide_banner -loglevel error -re -fflags +genpts \
    -stream_loop -1 -f concat -safe 0 -i "$PL" \
    -map 0:v:0 -map 0:a:0? \
    -vf fps=30,format=yuv420p \
    -c:v libx264 -profile:v main -level 4.1 \
    -x264-params "bframes=0:ref=1:keyint=60:min-keyint=60:scenecut=0" \
    -g 60 -keyint_min 60 -sc_threshold 0 -preset veryfast -tune zerolatency \
    -c:a aac -ar 48000 -ac 2 -b:a 128k \
    -f rtsp "$OUT"


elif [ -n "$FILE" ]; then
  ffmpeg -hide_banner -loglevel error -re -stream_loop -1 -fflags +genpts \
    -i "$FILE" -map 0:v:0 -map 0:a:0? -c copy -f rtsp "$OUT" \
  || ffmpeg -hide_banner -loglevel error -re -stream_loop -1 -fflags +genpts \
    -i "$FILE" -map 0:v:0 -map 0:a:0? \
    -vf fps=30,format=yuv420p \
    -c:v libx264 -profile:v main -level 4.1 \
    -x264-params "bframes=0:ref=1:keyint=60:min-keyint=60:scenecut=0" \
    -g 60 -keyint_min 60 -sc_threshold 0 -preset veryfast -tune zerolatency \
    -c:a aac -ar 48000 -ac 2 -b:a 128k \
    -f rtsp "$OUT"
else
  echo "Alias '$NAME' did not resolve to a folder or file."; sleep 5; exit 1
fi
