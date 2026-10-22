#!/bin/zsh
set -eu
cd "${0:A:h:h}"
[[ -d 'dist/Git Boy.app' ]] || scripts/build.sh
mkdir -p "$HOME/Applications" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs/GitBoy"
ditto 'dist/Git Boy.app' "$HOME/Applications/Git Boy.app"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$HOME/Applications/Git Boy.app"
node_path=$(command -v node)
python3 - "$PWD" "$node_path" <<'PY'
import os,sys,plistlib
root,node=sys.argv[1:]
p=os.path.expanduser('~/Library/LaunchAgents/com.sliker.gitboy.links.plist')
with open(p,'wb') as f:
 plistlib.dump({'Label':'com.sliker.gitboy.links','ProgramArguments':[node,root+'/integration/bridge.mjs','--http'],'RunAtLoad':True,'KeepAlive':True,'StandardOutPath':os.path.expanduser('~/Library/Logs/GitBoy/links.log'),'StandardErrorPath':os.path.expanduser('~/Library/Logs/GitBoy/links-error.log')},f)
PY
launchctl bootout "gui/$(id -u)/com.sliker.gitboy.links" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/com.sliker.gitboy.links.plist"
