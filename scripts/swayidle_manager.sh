#!/bin/sh

if [ -f "/run/current-system/sw/bin/swayidle" ]; then
	echo "swayidle is installed, starting..."
	swayidle -w 300 'swaylock -f' timeout 360 'hyprctl dispatch dmps off' resume 'hyprctl dispatch dpms on'
else
	echo "swayidle not detected, did not start"
fi;

