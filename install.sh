#!/usr/bin/env bash
# go tools installer v2.0.0 by lptech22
# Pakai: source <(curl -fsSL https://raw.githubusercontent.com/lptech22/go-tools/main/install.sh)
# Alpine: jalankan "bash" dulu, lalu perintah di atas.
# Dengan source, perintah go langsung aktif di sesi ini.

GO_VERSION="2.0.0"
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

# Deteksi lingkungan: termux, alpine, debian (Ubuntu), atau lainnya
if [ -n "$TERMUX_VERSION" ] || [ -d /data/data/com.termux ]; then
  OS_KIND="termux"
elif [ -f /etc/alpine-release ]; then
  OS_KIND="alpine"
elif command -v apt-get >/dev/null 2>&1; then
  OS_KIND="debian"
else
  OS_KIND="other"
fi

SUDO=""
[ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && SUDO="sudo"

# Folder Acode: sama dengan penyimpanan Android bila ada, kalau tidak di home
detect_acode() {
  if [ -d "$HOME/storage/shared" ]; then
    echo "$HOME/storage/shared/Acode"
  elif [ -d /storage/emulated/0 ]; then
    echo "/storage/emulated/0/Acode"
  else
    echo "$HOME/Acode"
  fi
}

pkg_install() {
  case "$OS_KIND" in
    termux) pkg install -y -o Dpkg::Options::=--force-confold "$@" ;;
    alpine) $SUDO apk add --no-cache "$@" ;;
    debian) $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
    *)      return 1 ;;
  esac
}

# step "pesan" perintah... : jalankan perintah dengan animasi spinner
step() {
  local msg="$1"; shift
  local jc=0 pid i=0 rc
  case $- in *m*) jc=1 ;; esac
  set +m
  "$@" >>"$LOG" 2>&1 </dev/null &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r${BLUE}%s${RESET} %s   " "${FRAMES[i]}" "$msg"
    i=$(( (i+1) % ${#FRAMES[@]} ))
    sleep 0.1
  done
  wait "$pid"; rc=$?
  [ "$jc" -eq 1 ] && set -m
  if [ "$rc" -eq 0 ]; then
    printf "\r${GREEN}✓${RESET} %s            \n" "$msg"
    return 0
  fi
  printf "\r${RED}✗${RESET} %s            \n" "$msg"
  echo "  ${DIM}Detail: $LOG${RESET}"
  return 1
}

# Login GitHub: panduan hanya tampil selama login, lalu dihapus
gh_login() {
  echo
  echo "${BOLD}Login GitHub${RESET} ${DIM}(cukup sekali)${RESET}"
  echo "${DIM}1. Copy link, lalu buka di browser${RESET}"
  echo "${DIM}2. Masukkan kode di bawah${RESET}"
  echo "${DIM}3. Tekan Authorize / Izinkan${RESET}"
  echo
  gh auth login -h github.com -p https -w 2>&1 | while IFS= read -r line; do
    case "$line" in
      *"First copy your one-time code"*)
        echo "${BOLD}Kode:${RESET} ${YELLOW}${BOLD}${line##* }${RESET}"
        ;;
      *"login/device"*)
        echo "${BOLD}Link:${RESET} ${BLUE}${line##* }${RESET}"
        echo "${DIM}Menunggu persetujuan di browser...${RESET}"
        ;;
    esac
  done
  # Hapus blok panduan (9 baris) kalau login berhasil
  if gh auth status >/dev/null 2>&1; then
    printf '\033[9A\033[J'
  fi
}

echo
echo "${BOLD}${BLUE}go tools${RESET} ${BOLD}v$GO_VERSION${RESET} ${DIM}by $GO_AUTHOR${RESET}"
echo "${DIM}──────────────────────────────${RESET}"

if [ "$OS_KIND" = "other" ]; then
  fail "OS ini belum didukung (Termux, Alpine, atau Ubuntu/Debian)"
  { return 1 2>/dev/null || exit 1; }
fi

# 1. Paket yang dibutuhkan (nama perintah:nama paket)
if [ "$OS_KIND" = "alpine" ]; then
  PAIRS="bash:bash curl:curl git:git gh:github-cli"
else
  PAIRS="curl:curl git:git gh:gh"
fi
need=()
for pair in $PAIRS; do
  cmd=${pair%%:*}; pk=${pair#*:}
  command -v "$cmd" >/dev/null 2>&1 || need+=("$pk")
done
if [ ${#need[@]} -gt 0 ]; then
  if [ "$OS_KIND" = "debian" ]; then
    step "Perbarui daftar paket" $SUDO apt-get update -qq || { return 1 2>/dev/null || exit 1; }
  fi
  step "Pasang ${need[*]}" pkg_install "${need[@]}" || {
    fail "Gagal memasang ${need[*]}"
    info "Pasang manual lalu jalankan ulang install (gh: https://cli.github.com)"
    { return 1 2>/dev/null || exit 1; }
  }
else
  ok "curl, git, gh sudah ada"
fi

# 2. Izin penyimpanan HP (hanya Termux)
if [ "$OS_KIND" = "termux" ] && [ ! -d "$HOME/storage/shared" ]; then
  info "Tekan ${BOLD}IZINKAN${RESET} di pop-up penyimpanan."
  termux-setup-storage
  for _ in $(seq 1 90); do
    [ -d "$HOME/storage/shared" ] && break
    sleep 1
  done
  # Kalau sudah berhasil, hapus baris petunjuk tadi
  [ -d "$HOME/storage/shared" ] && printf '\033[1A\033[2K'
fi
if [ "$OS_KIND" = "termux" ] && [ ! -d "$HOME/storage/shared" ]; then
  fail "Izin penyimpanan belum aktif"
  info "Jalankan ${BOLD}termux-setup-storage${RESET}, izinkan, lalu ulangi install"
  { return 1 2>/dev/null || exit 1; }
fi

ACODE_DIR=$(detect_acode)
mkdir -p "$ACODE_DIR"
ok "Folder Acode siap ${DIM}($ACODE_DIR)${RESET}"

# 3. Unduh dan pasang go.sh
[ -f "$HOME/.go.sh" ] && cp "$HOME/.go.sh" "$HOME/.go.sh.bak"
step "Unduh go tools v$GO_VERSION" curl -fsSL "$GO_URL" -o "$HOME/.go.sh.new" || { return 1 2>/dev/null || exit 1; }
mv "$HOME/.go.sh.new" "$HOME/.go.sh"
grep -q ".go.sh" "$HOME/.bashrc" 2>/dev/null || echo '[ -f ~/.go.sh ] && . ~/.go.sh' >> "$HOME/.bashrc"
if [ "$OS_KIND" = "alpine" ]; then
  grep -q ".go.sh" "$HOME/.profile" 2>/dev/null || echo '[ -f ~/.go.sh ] && . ~/.go.sh' >> "$HOME/.profile"
fi
ok "Perintah go terpasang"

# 4. Pengaturan Git
git config --global --get-all safe.directory 2>/dev/null | grep -qxF '*' || git config --global --add safe.directory '*'

# 5. Login GitHub
if ! gh auth status >/dev/null 2>&1; then
  gh_login
fi

if gh auth status >/dev/null 2>&1; then
  gh auth setup-git >/dev/null 2>&1
  login=$(gh api user --jq .login 2>/dev/null)
  ok "Login GitHub: ${BOLD}$login${RESET}"
  if [ -z "$(git config --global user.name)" ] && [ -n "$login" ]; then
    git config --global user.name "$login"
    git config --global user.email "$login@users.noreply.github.com"
  fi
else
  warn "Login GitHub belum selesai. Nanti jalankan: gh auth login"
fi

# Bersihkan fungsi bantuan, lalu aktifkan go di sesi ini
unset -f ok fail warn info step gh_login pkg_install detect_acode 2>/dev/null
. "$HOME/.go.sh"

echo
echo "${GREEN}${BOLD}✓ go tools v$GO_VERSION siap${RESET}"
echo " Untuk panduan penggunaan kirim perintah: ${BLUE}go help${RESET}"
