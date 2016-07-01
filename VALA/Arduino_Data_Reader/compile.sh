#!/bin/bash

FILES=("ArduinoInterface.vala" "SensorWindow.vala" "window.vala")
PACKAGES=("posix" "gtk+-3.0")
OPTIONS=("--target-glib=2.32")
OUTPUT="ArduinoInterface"

CMDOPTS="${OPTIONS[*]}"
for PKG in ${PACKAGES[@]}
do
  CMDOPTS="$CMDOPTS --pkg $PKG"
done
CMDOPTS="$CMDOPTS ${FILES[*]}"

CMDOPTS="$CMDOPTS -o $OUTPUT"
valac $CMDOPTS
