#!/bin/sh
# Get TLE from AMSAT Web and it's pushed to Predict configuration
# Predict it's developed by John A. Magliacane, KD2BD -  http://www.qsl.net/kd2bd/index.html

wget -qr http://www.amsat.org/amsat/ftp/keps/current/nasabare.txt -O /home/pi/nasabare.txt
/usr/bin/predict -u /home/pi/nasabare.txt
