polybar workspace 2>&1 | tee -a /tmp/polybar1.log &
disown
polybar clock 2>&1 | tee -a /tmp/polybar2.log & # should move to the right
disown
polybar tray 2>&1 | tee -a /tmp/polybar3.log &
disown
# polybar cpu 2>&1 | tee -a /tmp/polybar4.log & disown
#polybar battery 2>&1 | tee -a /tmp/polybar5.log & disown
# polybar sound 2>&1 | tee -a /tmp/polybar6.log & disown
# polybar wifitray 2>&1 | tee -a /tmp/polybar7.log & disown
polybar right 2>&1 | tee -a /tmp/polybar4.log &
disown
