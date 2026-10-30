# Astra Downloader (Mega Batch DL Tool)

Batch downloader for Mega links with real-time single-line progress, link auto-coercion, and duplicate detection.

### Prerequisites
pkg install megatools python zip -y

### How to Use
1. Add Mega links into `links.txt` (one per line).
2. Run:
   chmod +x astra-dl.sh
   ./astra-dl.sh -f links.txt -d "/sdcard/anime/Series Name"

### Status Tags
- [ File ] : Full filename
- [ Downloading ] : Progress percentage and file size
- [ Available ] : Already downloaded file (auto-skipped)
- [ Complete ] : Download completed
- [ Error ] : Download failed
