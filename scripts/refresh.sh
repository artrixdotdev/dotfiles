#!/bin/bash

# Add a delay before refreshing if it causes issues
sleep_time=0 # Change to 0.5 if needed

ags quit

sleep "$sleep_time"

ags run --gtk4

sleep "$((sleep_time + 1))"

notify-send "Refreshed!"

