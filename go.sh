GO_VERSION="1.9.3"
GO_AUTHOR="lptech22"
GO_ROOT="$HOME/storage/shared/Acode"
GO_BM="$HOME/.go_bookmarks"

C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'
C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'

_ok()   { echo "${C_GREEN}✓${C_RESET} $*"; }
_err()  { echo "${C_RED}✗${C_RESET} $*"; }
_warn() { echo "${C_YELLOW}!${C_RESET} $*"; }
_info() { echo "${C_BLUE}→${C_RESET} $*"; }

if [ -d "$HOME/storage/shared" ]; then
  mkdir -p "$GO_ROOT"
elif [ -t 1 ]; then
  _warn "Akses penyimpanan HP belum diizinkan. Jalankan: termux-setup-storage"
fi

_go_safe() {
  git config --global --get-all safe.directory 2>/dev/null | grep -qxF '*' || git config --global --add safe.directory '*'
}

# Bersihkan layar DAN riwayat scroll
_go_clear() {
  printf '\033[H\033[2J\033[3J'
}

alias c='printf "\033[H\033[2J\033[3J"'

_go_short() {
  echo "${1/#$HOME/~}"
}

# Lokasi satu baris: kalau sempit, bagian awal diganti …
_go_loc() {
  local p cols avail
  p=$(_go_short "$PWD")
  cols=$(tput cols 2>/dev/null || echo "${COLUMNS:-40}")
  avail=$((cols - 10))
  if [ "${#p}" -gt "$avail" ] && [ "$avail" -gt 2 ]; then
    p="…${p: -$((avail-1))}"
  fi
  echo "${C_DIM}Lokasi:${C_RESET} ${C_BLUE}$p${C_RESET}"
}

_go_title() {
  local bar
  printf -v bar '%*s' 30 ''
  bar=${bar// /─}
  echo "${C_BLUE}╭${bar}╮${C_RESET}"
  echo "${C_BLUE}│${C_RESET} ${C_BOLD}go tools${C_RESET} ${C_GREEN}v$GO_VERSION${C_RESET} ${C_DIM}by $GO_AUTHOR${C_RESET}  ${C_BLUE}│${C_RESET}"
  echo "${C_BLUE}╰${bar}╯${C_RESET}"
}

# Info git untuk folder aktif (diam saja kalau bukan folder git)
_go_gitinfo() {
  _go_safe
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  local br last changed
  br=$(git symbolic-ref --short -q HEAD 2>/dev/null || echo "detached")
  last=$(git log -1 --format='%h %s' 2>/dev/null)
  changed=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  echo "${C_DIM}Branch:${C_RESET} ${C_GREEN}$br${C_RESET}"
  echo "${C_DIM}Commit:${C_RESET} ${C_YELLOW}${last:-belum ada}${C_RESET}"
  if [ "$changed" -gt 0 ]; then
    echo "${C_DIM}Status:${C_RESET} ${C_YELLOW}$changed file belum di-commit${C_RESET}"
  else
    echo "${C_DIM}Status:${C_RESET} ${C_GREEN}bersih${C_RESET}"
  fi
}

# Detail folder aktif (layar dan riwayat dibersihkan, lalu detail ditampilkan)
_go_show() {
  _go_clear
  _go_title
  echo
  _go_loc
  _go_gitinfo
  echo
  echo "${C_BOLD}Isi folder:${C_RESET}"
  local f n=0
  for f in * .[!.]*; do
    [ -e "$f" ] || continue
    [ "$f" = ".git" ] && continue
    n=$((n+1))
    if [ -d "$f" ]; then
      echo " ${C_BLUE}$f/${C_RESET}"
    else
      echo " $f"
    fi
  done
  [ $n -eq 0 ] && echo " ${C_DIM}(kosong)${C_RESET}"
  echo
}

# Detail lengkap lokasi: path penuh tanpa dipotong
_go_lokasi() {
  _go_clear
  _go_title
  echo
  echo "${C_DIM}Folder:${C_RESET} ${C_BOLD}$(basename "$PWD")${C_RESET}"
  echo "${C_DIM}Path:${C_RESET}   ${C_BLUE}$(_go_short "$PWD")${C_RESET}"
  echo "${C_DIM}Penuh:${C_RESET}  $PWD"
  echo
  _go_gitinfo
  echo
}

# Menu pilih folder: nomor = masuk ke subfolder, . = buka folder ini
_go_browse() {
  local start="$PWD" choice i d
  local -a dirs
  [ -d "$GO_ROOT" ] && cd "$GO_ROOT"
  while true; do
    dirs=()
    for d in */; do
      [ -d "$d" ] && dirs+=("${d%/}")
    done
    _go_clear
    _go_title
    echo
    _go_loc
    _go_gitinfo
    echo
    i=1
    for d in "${dirs[@]}"; do
      printf " ${C_YELLOW}%2d)${C_RESET} ${C_BLUE}%s/${C_RESET}\n" "$i" "$d"
      i=$((i+1))
    done
    [ ${#dirs[@]} -eq 0 ] && echo " ${C_DIM}(tidak ada subfolder)${C_RESET}"
    local -a files=()
    for d in *; do
      [ -f "$d" ] && files+=("$d")
    done
    if [ ${#files[@]} -gt 0 ]; then
      echo
      echo "${C_BOLD}File:${C_RESET}"
      for d in "${files[@]}"; do
        printf " ${C_DIM}•${C_RESET} %s ${C_DIM}(%s)${C_RESET}\n" "$d" "$(ls -lh -- "$d" | awk '{print $5}')"
      done
    fi
    echo
    echo " ${C_DIM}0) naik   .) buka di sini   q) batal${C_RESET}"
    read -r -p "${C_BOLD}Pilih:${C_RESET} " choice
    case "$choice" in
      q) cd "$start"; return ;;
      .) _go_show; return ;;
      0) cd .. ;;
      ''|*[!0-9]*) _err "Pilihan tidak valid"; sleep 1 ;;
      *)
        if [ "$choice" -ge 1 ] && [ "$choice" -le ${#dirs[@]} ]; then
          cd "${dirs[$((choice-1))]}" || return 1
        else
          _err "Nomor tidak ada"; sleep 1
        fi
        ;;
    esac
  done
}

_go_co() {
  _go_safe
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    _err "Bukan folder git. Masuk ke folder proyek dulu: go nama"
    return 1
  fi

  if [ -z "$(git config user.email)" ] || [ -z "$(git config user.name)" ]; then
    _warn "Identitas Git belum diisi. Jalankan sekali:"
    echo '  git config --global user.name "lptech22"'
    echo '  git config --global user.email "lowoputih22@gmail.com"'
    return 1
  fi

  if ! git remote get-url origin >/dev/null 2>&1; then
    _err "Remote origin belum ada."
    return 1
  fi

  local branch committed=0 files deleted msg
  branch=$(git symbolic-ref --short -q HEAD) || {
    _err "Sedang detached HEAD. Pindah ke branch dulu: git switch main"
    return 1
  }

  git add -A

  if ! git diff --cached --quiet; then
    files=$(git diff --cached --name-only | wc -l | tr -d ' ')
    deleted=$(git diff --cached --name-status | awk '$1 == "D" {n++} END {print n+0}')
    msg="$*"
    [ -z "$msg" ] && msg="update $(date '+%Y-%m-%d %H:%M')"
    git commit -q -m "$msg" || { _err "Commit gagal"; return 1; }
    committed=1
    _ok "Commit dibuat: ${C_BOLD}$msg${C_RESET}"
    _info "File berubah: $files ${C_DIM}(dihapus: $deleted)${C_RESET}"
  fi

  if git fetch -q origin "$branch" 2>/dev/null; then
    if git rev-parse --verify -q "origin/$branch" >/dev/null; then
      local ahead behind
      ahead=$(git rev-list --count "origin/$branch..HEAD")
      behind=$(git rev-list --count "HEAD..origin/$branch")

      if [ "$committed" -eq 0 ]; then
        if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
          _info "Tidak ada perubahan file. Menyelaraskan $behind commit dari GitHub lalu mengirim $ahead commit lokal..."
        elif [ "$ahead" -gt 0 ]; then
          _info "Tidak ada perubahan file. Mengirim $ahead commit yang tertunda..."
        elif [ "$behind" -gt 0 ]; then
          _info "Tidak ada perubahan file. Mengambil $behind commit baru dari GitHub..."
        else
          _ok "Tidak ada perubahan. Sudah sinkron dengan origin/$branch."
          return 0
        fi
      fi

      if [ "$behind" -gt 0 ]; then
        if [ "$committed" -eq 1 ]; then
          _info "Ada $behind commit baru di GitHub, menyelaraskan..."
        fi
        if ! git pull --rebase --autostash origin "$branch"; then
          _err "Rebase gagal. Selesaikan konflik lalu: git rebase --continue"
          return 1
        fi
        ahead=$(git rev-list --count "origin/$branch..HEAD")
        if [ "$ahead" -eq 0 ]; then
          _ok "Lokal sudah diperbarui, tidak ada yang perlu dikirim."
          return 0
        fi
      fi
    else
      if [ "$committed" -eq 0 ]; then
        _info "Tidak ada perubahan file. Mengirim commit lokal ke origin/$branch..."
      fi
    fi
  else
    if [ "$committed" -eq 0 ]; then
      _info "Tidak ada perubahan file."
    fi
    _warn "Gagal mengambil data dari GitHub, mencoba push langsung."
  fi

  if git push -u origin "$branch"; then
    _ok "Terkirim ke ${C_BOLD}origin/$branch${C_RESET}"
    _info "Repo GitHub sekarang sama dengan folder lokal."
    _info "Cloudflare Pages deploy otomatis sekitar 30-60 detik."
  else
    _err "Push gagal. Commit tetap tersimpan di lokal."
    return 1
  fi
}

_go_pull() {
  _go_safe
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    _err "Bukan folder git. Masuk ke folder proyek dulu: go nama"
    return 1
  fi

  local branch before behind pick stashed=0
  branch=$(git symbolic-ref --short -q HEAD) || {
    _err "Sedang detached HEAD. Pindah ke branch dulu: git switch main"
    return 1
  }
  before=$(git rev-parse --short HEAD)

  if [ -n "$(git status --porcelain)" ]; then
    _warn "Ada perubahan belum di-commit:"
    git status --short
    echo
    echo " ${C_YELLOW}1)${C_RESET} simpan sementara (stash), lalu sinkron"
    echo " ${C_YELLOW}2)${C_RESET} commit dulu (go co), lalu sinkron"
    echo " ${C_YELLOW}3)${C_RESET} batal"
    read -r -p "${C_BOLD}Pilih:${C_RESET} " pick
    case "$pick" in
      1)
        git stash push -u -q -m "go pull $(date '+%Y-%m-%d %H:%M')" || { _err "Stash gagal."; return 1; }
        stashed=1
        ;;
      2)
        _go_co || return 1
        ;;
      *)
        _info "Dibatalkan."
        return 0
        ;;
    esac
  fi

  if ! git fetch -q origin "$branch"; then
    _err "Gagal mengambil dari GitHub. Cek koneksi atau login."
    [ "$stashed" -eq 1 ] && git stash pop -q
    return 1
  fi

  behind=$(git rev-list --count "HEAD..origin/$branch")
  if [ "$behind" -eq 0 ]; then
    _ok "Sudah up to date dengan origin/$branch."
  else
    if ! git pull -q --rebase origin "$branch"; then
      _err "Sinkron gagal (konflik). Selesaikan dulu, lalu: git rebase --continue"
      return 1
    fi
    _ok "Diperbarui: ${C_YELLOW}$before${C_RESET} → ${C_YELLOW}$(git rev-parse --short HEAD)${C_RESET} ($behind commit baru)"
    git diff --stat "$before" HEAD | tail -n 1
  fi

  if [ "$stashed" -eq 1 ]; then
    if git stash pop -q; then
      _ok "Perubahan lokal dikembalikan dari stash."
    else
      _err "Perubahan lokal bentrok dengan versi terbaru. Cek: git status"
      _info "Stash masih tersimpan, lihat dengan: git stash list"
      return 1
    fi
  fi
  return 0
}

_go_clone() {
  _go_safe
  if ! command -v gh >/dev/null 2>&1; then
    _err "GitHub CLI (gh) belum terpasang. Pasang dulu: pkg install gh"
    return 1
  fi

  if ! gh auth status >/dev/null 2>&1; then
    _warn "Belum login GitHub. Langkahnya:"
    echo "  1. Jalankan: ${C_BLUE}gh auth login${C_RESET}"
    echo "  2. Pilih: GitHub.com, lalu HTTPS, lalu Login with a web browser"
    echo "  3. Ikuti kode yang muncul di browser"
    echo "  4. Jalankan: ${C_BLUE}gh auth setup-git${C_RESET}"
    echo "Setelah itu ulangi: ${C_BLUE}go clone${C_RESET}"
    return 1
  fi
  gh auth setup-git >/dev/null 2>&1

  local -a full privs
  local line priv
  while IFS=$'\t' read -r line priv; do
    full+=("$line")
    privs+=("$priv")
  done < <(gh repo list --limit 200 --json nameWithOwner,isPrivate --jq '.[] | "\(.nameWithOwner)\t\(.isPrivate)"' 2>/dev/null)

  if [ ${#full[@]} -eq 0 ]; then
    _err "Tidak ada repo ditemukan untuk akun ini."
    return 1
  fi

  _go_clear
  _go_title
  echo
  echo "${C_BOLD}Repo GitHub kamu:${C_RESET}"
  local k tag
  for k in "${!full[@]}"; do
    tag=""
    [ "${privs[$k]}" = "true" ] && tag=" ${C_YELLOW}(privat)${C_RESET}"
    printf " ${C_YELLOW}%2d)${C_RESET} ${C_BLUE}%s${C_RESET}%b\n" $((k+1)) "${full[$k]##*/}" "$tag"
  done
  echo
  echo " ${C_DIM}q) batal${C_RESET}"
  echo

  local ans t ok sel=()
  while true; do
    read -r -p "${C_BOLD}Pilih nomor${C_RESET} ${C_DIM}(contoh: 3 atau 1 3 5)${C_RESET}: " ans
    [ "$ans" = "q" ] && return 0
    ok=1
    sel=()
    for t in $ans; do
      if [[ "$t" =~ ^[0-9]+$ ]] && [ "$t" -ge 1 ] && [ "$t" -le "${#full[@]}" ]; then
        sel+=("$t")
      else
        _err "Nomor tidak valid: $t"
        ok=0
        break
      fi
    done
    if [ "$ok" -eq 1 ] && [ ${#sel[@]} -gt 0 ]; then break; fi
    _info "Coba lagi, atau q untuk batal."
  done

  mkdir -p "$GO_ROOT"
  local idx repo name target last=""
  for idx in "${sel[@]}"; do
    repo="${full[$((idx-1))]}"
    name="${repo##*/}"
    target="$GO_ROOT/$name"
    if [ -e "$target" ]; then
      _warn "Dilewati, folder sudah ada: $name"
      continue
    fi
    if gh repo clone "$repo" "$target" >/dev/null; then
      _ok "Berhasil: ${C_BOLD}$name${C_RESET}"
      last="$target"
    else
      _err "Gagal clone: $name"
    fi
  done

  if [ ${#sel[@]} -eq 1 ] && [ -n "$last" ]; then
    cd "$last" && _go_show
  elif [ -n "$last" ]; then
    _info "Proyek ada di $(_go_short "$GO_ROOT"). Buka dengan: go nama"
  fi
}

_go_update() {
  local url="https://raw.githubusercontent.com/lptech22/go-tools/main/go.sh"
  local tmp="$HOME/.go.sh.latest" latest ans
  _info "Mengecek versi terbaru di GitHub..."
  if ! curl -fsSL "$url" -o "$tmp" 2>/dev/null; then
    rm -f "$tmp"
    _err "Gagal mengunduh dari GitHub. Cek koneksi internet."
    return 1
  fi
  latest=$(sed -n 's/^GO_VERSION="\(.*\)"$/\1/p' "$tmp" | head -1)
  if [ -z "$latest" ]; then
    rm -f "$tmp"
    _err "File dari GitHub tidak valid, update dibatalkan."
    return 1
  fi
  if cmp -s "$tmp" "$HOME/.go.sh"; then
    rm -f "$tmp"
    _ok "Sudah versi terbaru ${C_GREEN}(v$GO_VERSION)${C_RESET}."
    return 0
  fi
  echo "${C_BOLD}Versi terpasang:${C_RESET} ${C_YELLOW}v$GO_VERSION${C_RESET}"
  echo "${C_BOLD}Versi terbaru:${C_RESET}   ${C_GREEN}v$latest${C_RESET}"
  read -r -p "${C_BOLD}Pasang sekarang?${C_RESET} ${C_DIM}[y/N]${C_RESET} " ans
  case "$ans" in
    y|Y)
      cp "$HOME/.go.sh" "$HOME/.go.sh.bak" 2>/dev/null
      mv "$tmp" "$HOME/.go.sh"
      . "$HOME/.go.sh"
      _ok "Update berhasil. Sekarang ${C_GREEN}v$GO_VERSION${C_RESET}. Backup lama: ${C_DIM}~/.go.sh.bak${C_RESET}"
      ;;
    *)
      rm -f "$tmp"
      _info "Update dibatalkan."
      ;;
  esac
}

_go_help_line() {
  printf " ${C_BLUE}%-16s${C_RESET} %s\n" "$1" "$2"
}

go() {
  case "$1" in
    "") _go_browse ;;
    version|-v|--version)
      echo "${C_BOLD}go tools${C_RESET} ${C_GREEN}v$GO_VERSION${C_RESET} ${C_DIM}by $GO_AUTHOR${C_RESET}"
      ;;
    help)
      _go_clear
      _go_title
      echo
      _go_help_line "go"             "menu pilih folder (mulai dari Acode)"
      _go_help_line "go lokasi"      "detail lokasi sekarang (path lengkap)"
      _go_help_line "c"              "bersihkan layar dan riwayat"
      _go_help_line "go acode"       "folder Acode"
      _go_help_line "go nama"        "proyek di Acode / bookmark"
      _go_help_line "go new nama"    "buat proyek baru"
      _go_help_line "go clone"       "pilih repo GitHub dengan nomor, lalu clone"
      _go_help_line "go pull"        "ambil versi terbaru dari GitHub"
      _go_help_line "go co [pesan]"  "commit, sinkron, dan push"
      _go_help_line "go add nama"    "bookmark folder ini"
      _go_help_line "go list"        "daftar bookmark & proyek"
      _go_help_line "go del nama"    "hapus bookmark"
      _go_help_line "go ss | go home" "penyimpanan HP / home Termux"
      _go_help_line "go version"     "tampilkan versi"
      _go_help_line "go update"      "cek dan pasang versi terbaru dari GitHub"
      echo
      ;;
    lokasi) _go_lokasi ;;
    c) _go_clear ;;
    update) _go_update ;;
    acode) cd "$GO_ROOT" && _go_show || return 1 ;;
    ss) cd "$HOME/storage/shared" && _go_show || return 1 ;;
    home) cd "$HOME" && _go_show ;;
    co) shift; _go_co "$@" ;;
    pull) _go_pull ;;
    clone) _go_clone ;;
    new)
      [ -z "$2" ] && { _err "Pakai: go new nama"; return 1; }
      mkdir -p "$GO_ROOT/$2" && cd "$GO_ROOT/$2" && _go_show
      ;;
    add)
      [ -z "$2" ] && { _err "Pakai: go add nama"; return 1; }
      touch "$GO_BM"
      grep -v "^$2|" "$GO_BM" > "$GO_BM.tmp"
      echo "$2|$PWD" >> "$GO_BM.tmp"
      mv "$GO_BM.tmp" "$GO_BM"
      _ok "Bookmark tersimpan: ${C_BOLD}$2${C_RESET} → $(_go_short "$PWD")"
      ;;
    del)
      [ -z "$2" ] && { _err "Pakai: go del nama"; return 1; }
      touch "$GO_BM"
      grep -v "^$2|" "$GO_BM" > "$GO_BM.tmp"
      mv "$GO_BM.tmp" "$GO_BM"
      _ok "Bookmark dihapus: $2"
      ;;
    list)
      echo "${C_BOLD}Bookmark:${C_RESET}"
      if [ -s "$GO_BM" ]; then
        sed "s/|/ → /; s/^/ ${C_BLUE}/; s/ → /${C_RESET} → /" "$GO_BM"
      else
        echo " ${C_DIM}(kosong)${C_RESET}"
      fi
      echo
      echo "${C_BOLD}Proyek di Acode:${C_RESET}"
      ls -1 "$GO_ROOT" 2>/dev/null | sed "s/^/ ${C_BLUE}/; s/\$/${C_RESET}/" || _err "Acode tidak ditemukan"
      ;;
    *)
      if [ -d "$GO_ROOT/$1" ]; then
        cd "$GO_ROOT/$1" && _go_show
      else
        local p
        p=$(grep "^$1|" "$GO_BM" 2>/dev/null | head -1 | cut -d'|' -f2-)
        if [ -n "$p" ] && [ -d "$p" ]; then
          cd "$p" && _go_show
        else
          _err "Tidak ditemukan: $1"
          return 1
        fi
      fi
      ;;
  esac
}
