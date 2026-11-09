#!/data/data/com.termux/files/usr/bin/bash
set -e

URL="https://raw.githubusercontent.com/lptech22/go-tools/main/go.sh"

command -v curl >/dev/null || pkg install -y curl
command -v git  >/dev/null || pkg install -y git

[ -f "$HOME/.go.sh" ] && cp "$HOME/.go.sh" "$HOME/.go.sh.bak"
curl -fsSL "$URL" -o "$HOME/.go.sh"

grep -q ".go.sh" "$HOME/.bashrc" 2>/dev/null || echo '[ -f ~/.go.sh ] && . ~/.go.sh' >> "$HOME/.bashrc"

echo "go tools terpasang. Tutup lalu buka Termux lagi, atau jalankan: . ~/.go.sh"
