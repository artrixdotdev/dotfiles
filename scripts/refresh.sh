#!/bin/bash


ags quit
sleep 0.3
ags run --gtk4

sleep 1

notify-send "Refreshed!"
