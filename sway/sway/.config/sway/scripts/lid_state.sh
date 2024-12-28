#!/usr/bin/env bash

# Wait for Kanshi and Sway before running this script
sleep 2

if grep -q closed /proc/acpi/button/lid/LID*/state; then
    kanshictl switch docked_closed
else
    kanshictl switch docked_open
fi

