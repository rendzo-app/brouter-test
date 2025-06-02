#!/bin/sh

cd "$(dirname "$0")"

# ─── Segment Download Step ─────────────────────────────────────────────
SEGMENT_TARGET_PATH="../segments4"

# Only download if missing or empty
if [ ! -d "$SEGMENT_TARGET_PATH" ] || [ -z "$(ls -A "$SEGMENT_TARGET_PATH" 2>/dev/null)" ]; then
  echo "[INFO] No segment files found — downloading..."
  /bin/download_segments.sh
else
  echo "[INFO] Segment files already exist — skipping download."
fi

# ─── BRouter standalone server ─────────────────────────────────────────
# java -cp brouter.jar btools.brouter.RouteServer <segmentdir> <profile-map> <customprofiledir> <port> <maxthreads> [bindaddress]

# maxRunningTime is the request timeout in seconds, set to 0 to disable timeout
JAVA_OPTS="-Xmx40g -Xms256M -Xmn256M -DmaxRunningTime=300"

# If paths are unset, first search in locations matching the directory structure
# as found in the official BRouter zip archive
CLASSPATH=${CLASSPATH:-"../brouter.jar"}
SEGMENTSPATH=${SEGMENTSPATH:-"$SEGMENT_TARGET_PATH"}
PROFILESPATH=${PROFILESPATH:-"../profiles2"}
CUSTOMPROFILESPATH=${CUSTOMPROFILESPATH:-"../customprofiles"}

# Otherwise try to locate files inside the source checkout
if [ ! -e "$CLASSPATH" ]; then
    CLASSPATH="$(ls ../../../brouter-server/build/libs/brouter-*-all.jar | sort --reverse --version-sort | head --lines 1)"
fi
if [ ! -e "$SEGMENTSPATH" ]; then
    SEGMENTSPATH="../../segments4"
fi
if [ ! -e "$PROFILESPATH" ]; then
    PROFILESPATH="../../profiles2"
fi
if [ ! -e "$CUSTOMPROFILESPATH" ]; then
    CUSTOMPROFILESPATH="../customprofiles"
fi

echo "[INFO] Starting BRouter server on port 17777..."
# java $JAVA_OPTS -cp "$CLASSPATH" btools.server.RouteServer "$SEGMENTSPATH" "$PROFILESPATH" "$CUSTOMPROFILESPATH" 17777 16 $BINDADDRESS

exec java -cp /brouter.jar btools.server.RouteServer /segments4 /profiles2 /profiles2 17777 4