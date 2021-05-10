#!/bin/sh

# Get environment variables
env | grep 'DB2' > /home/shiny/.Renviron
chown shiny.shiny /home/shiny/.Renviron

# Make sure the directory for individual app logs exists
mkdir -p /var/log/shiny-server
chown shiny.shiny /var/log/shiny-server

exec shiny-server >> /var/log/shiny-server.log 2>&1