#!/bin/bash
# run this script in cronjob by editing crontab -e and following line
# @reboot /bin/bash <path/to/this/script>
export GIT_SYNC_DIRECTORY="${HOME}/my_codes/github_repos/my_repos/codesScripts"
export GIT_SYNC_COMMAND="/usr/local/bin/git-sync"
export GIT_SYNC_INTERVAL=900
/bin/bash /usr/local/bin/git-sync-on-inotify