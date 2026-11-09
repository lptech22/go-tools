#!/data/data/com.termux/files/usr/bin/bash
# go tools installer v1.6.1 by lptech22

GO_VERSION="1.6.1"
GO_AUTHOR="lptech22"
GO_URL="https://raw.githubusercontent.com/lptech22/go-tools/main/go.sh"
LOG="$HOME/.go-install.log"
FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'
BOLD=$'\033[1m'; DIM=$'\033[2m'; RESET=$'\033[0m'

ok()   { echo "${GREEN}✓${RESET} $*"; }
fail() { echo "${RED}✗${RESET} $*"; }
warn() { echo "${YELLOW}!${RESET} $*"; }
info() { echo "${BLUE}→${RESET} $*"; }

: > "$LOG"

# step "pesan" perintah... : jalankan perintah dengan animasi spinner
step() {
  local msg="$1"; shift
  "$@" >>"$LOG" 2>&1 </dev/null &
  local pid=$! i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r${BLUE}%s${RESET} %s   " "${FRAMES[i]}" "$msg"
    i=$(( (i+1) % ${#FRAMES[@]} ))
    sleep 0.1
  done
  if wait "$pid"; then
    printf "\r${GREEN}✓${RESET} %s            \n" "$msg"
    return 0
  fi
  printf "\r${RED}✗${RESET} %s            \n" "$msg"
  echo "  ${DIM}Detail: $LOG${RESET}"
  return 1
}

echo
echo "${BOLD}${BLUE}go tools${RESET} ${BOLD}v$GO_VERSION${RESET} ${DIM}by $GO_AUTHOR${RESET}"
echo "${DIM}──────────────────────────────${RESET}"

# 1. Paket yang dibutuhkan
need=()
for p in curl git gh; do
  command -v "$p" >/dev/null 2>&1 || need+=("$p")
done
if [ ${#need[@]} -gt 0 ]; then
  step "Pasang ${need[*]}" pkg install -y -o Dpkg::Options::=--force-confold "${need[@]}" || exit 1
else
  ok "curl, git, gh sudah ada"
fi

# 2. Izin penyimpanan HP
if [ ! -d "$HOME/storage/shared" ]; then
  warn "Tekan ${BOLD}IZINKAN${RESET} di pop-up penyimpanan."
  termux-setup-storage
  for _ in $(seq 1 90); do
    [ -d "$HOME/storage/shared" ] && break
    sleep 1
  done
fi
if [ ! -d "$HOME/storage/shared" ]; then
  fail "Izin penyimpanan belum aktif"
  info "Jalankan ${BOLD}termux-setup-storage${RESET}, izinkan, lalu ulangi install"
  exit 1
fi
mkdir -p "$HOME/storage/shared/Acode"
ok "Penyimpanan siap ${DIM}(Acode)${RESET}"

# 3. Unduh dan pasang go.sh
[ -f "$HOME/.go.sh" ] && cp "$HOME/.go.sh" "$HOME/.go.sh.bak"
step "Unduh go tools v$GO_VERSION" curl -fsSL "$GO_URL" -o "$HOME/.go.sh.new" || exit 1
mv "$HOME/.go.sh.new" "$HOME/.go.sh"
grep -q ".go.sh" "$HOME/.bashrc" 2>/dev/null || echo '[ -f ~/.go.sh ] && . ~/.go.sh' >> "$HOME/.bashrc"
ok "Perintah go terpasang"

# 4. Pengaturan Git
git config --global --get-all safe.directory 2>/dev/null | grep -qxF '*' || git config --global --add safe.directory '*'

# 5. Login GitHub
if gh auth status >/dev/null 2>&1; then
  ok "Sudah login GitHub"
else
  echo
  info "Login GitHub: pilih ${BOLD}GitHub.com${RESET} → ${BOLD}HTTPS${RESET} → ${BOLD}Login with a web browser${RESET}"
  info "Salin kode, buka link di browser, lalu tempel kodenya"
  echo
  gh auth login -h github.com -p https -w
fi

if gh auth status >/dev/null 2>&1; then
  gh auth setup-git >/dev/null 2>&1
  ok "Git terhubung ke GitHub"
  if [ -z "$(git config --global user.name)" ]; then
    login=$(gh api user --jq .login 2>/dev/null)
    if [ -n "$login" ]; then
      git config --global user.name "$login"
      git config --global user.email "$login@users.noreply.github.com"
      ok "Identitas Git: ${BOLD}$login${RESET}"
    fi
  fi
else
  warn "Login GitHub belum selesai. Nanti jalankan: gh auth login"
fi

echo
echo "${GREEN}${BOLD}✓ go tools v$GO_VERSION siap${RESET}"
echo
warn "${BOLD}Tutup Termux lalu buka lagi${RESET}, atau ketik: ${BOLD}source ~/.bashrc${RESET}"
echo "  Lalu coba: ${BLUE}go help${RESET}   atau   ${BLUE}go clone${RESET}"
