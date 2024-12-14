# MOTD

function show_motd() {
    # ANSI color codes
    local CYAN='\033[0;36m'
    local GREEN='\033[0;32m'
    local NC='\033[0m'
    
    # Randomly choose between 0 and 1
    if (( RANDOM % 2 )); then
        # Cyberpunk theme
        echo "${CYAN}"
        cat << EOF
┌─────────────────────────────────────────┐
│  ⚡ SYSTEM: $(uname -n)                  
│  ⚡ UPTIME: $(uptime | cut -d ',' -f1)   
│  ⚡ MACHINE: $(uname -n)                          
│  ⚡ LOGIN TIME: $(date +%H:%M)
│  ⚡ LAST LOGIN: $(last -1 $USER | head -1 | awk '{print $4,$5,$6}')
│  ⚡ STATUS: ONLINE                          
└─────────────────────────────────────────┘
EOF
    else
        # Minimalist hacker theme
        echo "${GREEN}"
        cat << EOF
▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
  >> sys.init
  >> uptime: $(uptime | cut -d ',' -f1)
  >> machine: $(uname -n)
  >> login time: $(date +%H:%M)
  >> last login: $(last -1 $USER | head -1 | awk '{print $4,$5,$6}')
  >> status: ONLINE
▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
EOF
    fi
    echo "${NC}"
}

# Call the function when shell starts
show_motd
