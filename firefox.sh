#!/usr/bin/bash

# If the system-level Flash extension is installed, then delete any remnants
# of the old installer script *before* Firefox is started. This is not inside
# firefox-plugins-installer, as then it might start deleting the plugins as
# Firefox is trying to read them.
if [ -f /app/firefox/plugins/libflashplayer.so ]; then
  rm -rf ~/.mozilla/plugins/libflashplayer.so ${XDG_DATA_HOME}/firefox-plugins
else
  # Launch the script that installs the plugins (if needed) in the background
  # so it installs them while Firefox is already running, avoiding the user
  # to wait
  /app/bin/firefox-plugins-installer &
fi

export TMPDIR=$XDG_CACHE_HOME/tmp
exec /app/extra/firefox/firefox "$@"
