#!/data/data/com.termux/files/usr/bin/bash
# go tools installer v1.5.0 by lptech22

GO_VERSION="1.5.0"
GO_AUTHOR="lptech22"
GO_URL="https://raw.githubusercontent.com/lptech22/go-tools/main/go.sh"
LOG="$HOME/.go-install.log"
FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

: > "$LOG"

# step "pesan" perintah... : jalankan perintah dengan animasi spinner
step() {
  local msg="$1"; shift
  "$@" >>"$LOG" 2>&1 </dev/null &
  local pid=$! i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r %s %s   " "${FRAMES[i]}" "$msg"
    i=$(( (i+1) % ${#FRAMES[@]} ))
    sleep 0.1
  done
  if wait "$pid"; then
    printf "\r ✓ %s            \n" "$msg"
    return 0
  fi
  printf "\r ✗ %s            \n" "$msg"
  echo "   Detail ada di: $LOG"
  return 1
}

echo
echo " go tools v$GO_VERSION by $GO_AUTHOR"
echo " ------------------------------"

# 1. Paket yang dibutuhkan
need=()
for p in curl git gh; do
  command -v "$p" >/dev/null 2>&1 || need+=("$p")
done
if [ ${#need[@]} -gt 0 ]; then
  step "Memasang ${need[*]}" pkg install -y -o Dpkg::Options::=--force-confold "${need[@]}" || exit 1
else
  echo " ✓ curl, git, gh sudah ada"
fi

# 2. Izin penyimpanan HP
if [ ! -d "$HOME/storage/shared" ]; then
  echo " ! Meminta izin penyimpanan. Tekan Izinkan di layar."
  termux-setup-storage >/dev/null 2>&1
  for _ in $(seq 1 60); do
    [ -d "$HOME/storage/shared" ] && break
    sleep 1
  done
fi
if [ ! -d "$HOME/storage/shared" ]; then
  echo " ✗ Izin penyimpanan belum aktif. Jalankan ulang install.sh"
  exit 1
fi
mkdir -p "$HOME/storage/shared/Acode"
echo " ✓ Akses penyimpanan siap (folder Acode)"

# 3. Unduh dan pasang go.sh
[ -f "$HOME/.go.sh" ] && cp "$HOME/.go.sh" "$HOME/.go.sh.bak"
step "Mengunduh go tools v$GO_VERSION" curl -fsSL "$GO_URL" -o "$HOME/.go.sh.new" || exit 1
mv "$HOME/.go.sh.new" "$HOME/.go.sh"
grep -q ".go.sh" "$HOME/.bashrc" 2>/dev/null || echo '[ -f ~/.go.sh ] && . ~/.go.sh' >> "$HOME/.bashrc"
echo " ✓ Perintah go dipasang"

# 4. Pengaturan Git
git config --global --get-all safe.directory 2>/dev/null | grep -qxF '*' || git config --global --add safe.directory '*'

# 5. Login GitHub
if gh auth status >/dev/null 2>&1; then
  echo " ✓ Sudah login GitHub"
else
  echo
  echo " Login GitHub belum ada. Ikuti langkah ini:"
  echo "   - Pilih GitHub.com, lalu HTTPS"
  echo "   - Pilih Login with a web browser"
  echo "   - Salin kode yang muncul, buka link di browser, lalu tempel kodenya"
  echo
  gh auth login -h github.com -p https -w
fi

if gh auth status >/dev/null 2>&1; then
  gh auth setup-git >/dev/null 2>&1
  echo " ✓ Git terhubung ke GitHub"
  if [ -z "$(git config --global user.name)" ]; then
    login=$(gh api user --jq .login 2>/dev/null)
    if [ -n "$login" ]; then
      git config --global user.name "$login"
      git config --global user.email "$login@users.noreply.github.com"
      echo " ✓ Identitas Git: $login"
    fi
  fi
else
  echo " ! Login GitHub belum selesai. Jalankan nanti: gh auth login"
fi

echo
echo " ✓ go tools v$GO_VERSION siap."
echo " Tutup lalu buka Termux, atau jalankan: . ~/.go.sh"
echo " Coba: go help   atau   go clone"
