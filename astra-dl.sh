#!/bin/bash

SKY_BLUE='\033[0;36m'
WHITE='\033[0;37m'
DARK_ORANGE='\033[38;5;208m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

while getopts d:f: flag; do
  case "${flag}" in
    d) destination=${OPTARG};;
    f) file=${OPTARG};;
    *) echo -e "${RED}Error: Usage: $0 -f links.txt -d /path${RESET}" >&2
       exit 1;;
  esac
done

if [[ -z "$destination" || -z "$file" ]]; then
  echo -e "${RED}Error: Destination (-d) and File (-f) are required.${RESET}" >&2
  exit 1
fi

mkdir -p "$destination"

echo -e "${SKY_BLUE}[ Queue List ]${RESET}"
echo -e "${SKY_BLUE}Destination :${RESET} ${WHITE}$destination${RESET}"
echo -e "${SKY_BLUE}Input File  :${RESET} ${WHITE}$file${RESET}"
echo ""

while IFS= read -r line || [[ -n "$line" ]]; do
  LINK=$(echo "$line" | tr -d '\r' | xargs)
  [[ "$LINK" != *"mega.nz"* ]] && continue

  LINK=$(echo "$LINK" | sed 's/^.*\(https\)/https/')

  if [[ "$LINK" == *"/file/"* ]]; then
    replaceHashtag=${LINK/\#/!}
    partToReplace="/file/"
    replaceWith="/#!"
    LINK=${replaceHashtag/$partToReplace/$replaceWith}
  fi

  echo -e "${SKY_BLUE}▶ Link:${RESET} ${WHITE}$LINK${RESET}"

  python3 -u -c '
import sys, re, os, signal

def handle_sigint(sig, frame):
    sys.exit(0)

signal.signal(signal.SIGINT, handle_sigint)

dest = sys.argv[1]
link = sys.argv[2]

cmd = f"megadl --path=\"{dest}\" \"{link}\" 2>&1"
p = os.popen(cmd)

status = "complete"
target_file = ""
err_msg = ""
filename_printed = False

buf = ""
try:
    while True:
        ch = p.read(1)
        if not ch:
            break
        if ch in ("\r", "\n"):
            line = buf.strip()
            buf = ""
            if not line:
                continue

            if "Local file already exists:" in line:
                status = "available"
                target_file = line.split("Local file already exists:")[-1].strip().split("/")[-1]
            elif "ERROR" in line or "failed" in line:
                status = "error"
                err_msg = line
            elif "%" in line:
                m_fn = re.search(r"^(.*?):\s*[0-9.]+\s*%", line)
                if m_fn and not filename_printed:
                    full_fn = m_fn.group(1).strip()
                    target_file = full_fn
                    print(f"\033[0;36m[ File ]\033[0m \033[0;37m{full_fn}\033[0m")
                    filename_printed = True

                m_pct = re.search(r"([0-9.]+)%", line)
                pct = m_pct.group(1) if m_pct else "0.0"

                m_sz = re.search(r"([0-9.]+\s*[A-Za-z]+)(?:\s*\([0-9]+\s*bytes\))?\s*of\s*([0-9.]+\s*[A-Za-z]+)", line)
                if m_sz:
                    cur_sz = m_sz.group(1)
                    tot_sz = m_sz.group(2)
                else:
                    cur_sz = "--"
                    tot_sz = "--"

                out = f"\r\033[2K\033[0;33m[ Downloading ]\033[0m \033[0;36m|\033[0m \033[0;37mProgress {pct}% • {cur_sz}\033[0m \033[0;36m|\033[0m \033[0;37mSize: {tot_sz}\033[0m"
                sys.stdout.write(out)
                sys.stdout.flush()
            elif "Downloaded" in line:
                target_file = line.replace("Downloaded", "").strip()
        else:
            buf += ch
except (KeyboardInterrupt, SystemExit):
    p.close()
    sys.exit(0)

p.close()

if status == "available":
    print(f"\r\033[2K\033[38;5;208m[ Available ]\033[0m \033[0;37m{target_file}\033[0m\n")
elif status == "error":
    print(f"\r\033[2K\033[0;31m[ Error ]\033[0m \033[0;37m{err_msg}\033[0m\n")
else:
    print(f"\r\033[2K\033[0;32m[ Complete ]\033[0m \033[0;37m{target_file}\033[0m\n")
' "$destination" "$LINK"

done < "$file"

echo -e "${GREEN}• Process Completed${RESET}"
