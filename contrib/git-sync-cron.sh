#!/bin/bash
# run this script in cronjob by editing crontab -e and following line
# @reboot /bin/bash <path/to/this/script>
export GIT_SYNC_DIRECTORY="<path-to-your-git-repo>"
export GIT_SYNC_COMMAND="/usr/local/bin/git-sync"
export GIT_SYNC_INTERVAL=900
/bin/bash /usr/local/bin/git-sync-on-inotify