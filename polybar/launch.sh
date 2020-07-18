# Basic script to kill all old bars and launch new.

# Terminate already running bad instances
killall -9 polybar

# Wait until the processes have been shut down
while grep -x polybar >/dev/null; do sleep 1; done

# Launch the example bar
polybar example &

