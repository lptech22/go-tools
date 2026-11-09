GO_ROOT="$HOME/storage/shared/Acode"
GO_BM="$HOME/.go_bookmarks"

if [ -d "$HOME/storage/shared" ]; then
  mkdir -p "$GO_ROOT"
elif [ -t 1 ]; then
  echo "Akses penyimpanan HP belum diizinkan. Jalankan: termux-setup-storage"
fi

_go_safe() {
  git config --global --get-all safe.directory 2>/dev/null | grep -qxF '*' || git config --global --add safe.directory '*'
}

_go_browse() {
  local start="$PWD" choice i d
  local -a dirs
  [ -d "$GO_ROOT" ] && cd "$GO_ROOT"
  while true; do
    dirs=()
    for d in */; do
      [ -d "$d" ] && dirs+=("${d%/}")
    done
    echo
    echo "Lokasi: $PWD"
    i=1
    for d in "${dirs[@]}"; do
      echo " $i) $d"
      i=$((i+1))
    done
    [ ${#dirs[@]} -eq 0 ] && echo " (tidak ada subfolder)"
    echo " 0) naik   .) di sini   q) batal"
    read -r -p "Pilih: " choice
    case "$choice" in
      q) cd "$start"; return ;;
      .) echo "Sekarang di: $PWD"; return ;;
      0) cd .. ;;
      ''|*[!0-9]*) echo "Pilihan tidak valid" ;;
      *)
        if [ "$choice" -ge 1 ] && [ "$choice" -le ${#dirs[@]} ]; then
          cd "${dirs[$((choice-1))]}"
        else
          echo "Nomor tidak ada"
        fi
        ;;
    esac
  done
}

_go_co() {
  _go_safe
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Bukan folder git. Masuk ke folder proyek dulu: go nama"
    return 1
  fi

  if [ -z "$(git config user.email)" ] || [ -z "$(git config user.name)" ]; then
    echo "Identitas Git belum diisi. Jalankan sekali:"
    echo '  git config --global user.name "lptech22"'
    echo '  git config --global user.email "lowoputih22@gmail.com"'
    return 1
  fi

  if ! git remote get-url origin >/dev/null 2>&1; then
    echo "Remote origin belum ada."
    return 1
  fi

  local branch committed=0 files deleted msg
  branch=$(git symbolic-ref --short -q HEAD) || {
    echo "Sedang detached HEAD. Pindah ke branch dulu: git switch main"
    return 1
  }

  git add -A

  if ! git diff --cached --quiet; then
    files=$(git diff --cached --name-only | wc -l | tr -d ' ')
    deleted=$(git diff --cached --name-status | awk '$1 == "D" {n++} END {print n+0}')
    msg="$*"
    [ -z "$msg" ] && msg="update $(date '+%Y-%m-%d %H:%M')"
    git commit -q -m "$msg" || { echo "Commit gagal"; return 1; }
    committed=1
    echo "Commit dibuat: $msg"
    echo "File berubah: $files (dihapus: $deleted)"
  fi

  if git fetch -q origin "$branch" 2>/dev/null; then
    if git rev-parse --verify -q "origin/$branch" >/dev/null; then
      local ahead behind
      ahead=$(git rev-list --count "origin/$branch..HEAD")
      behind=$(git rev-list --count "HEAD..origin/$branch")

      if [ "$committed" -eq 0 ]; then
        if [ "$ahead" -gt 0 ] && [ "$behind" -gt 0 ]; then
          echo "Tidak ada perubahan file. Menyelaraskan $behind commit dari GitHub lalu mengirim $ahead commit lokal..."
        elif [ "$ahead" -gt 0 ]; then
          echo "Tidak ada perubahan file. Mengirim $ahead commit yang tertunda..."
        elif [ "$behind" -gt 0 ]; then
          echo "Tidak ada perubahan file. Mengambil $behind commit baru dari GitHub..."
        else
          echo "Tidak ada perubahan file."
          echo "Sudah sinkron dengan origin/$branch."
          return 0
        fi
      fi

      if [ "$behind" -gt 0 ]; then
        if [ "$committed" -eq 1 ]; then
          echo "Ada $behind commit baru di GitHub, menyelaraskan..."
        fi
        if ! git pull --rebase --autostash origin "$branch"; then
          echo "Rebase gagal. Selesaikan konflik lalu: git rebase --continue"
          return 1
        fi
        ahead=$(git rev-list --count "origin/$branch..HEAD")
        if [ "$ahead" -eq 0 ]; then
          echo "Lokal sudah diperbarui, tidak ada yang perlu dikirim."
          return 0
        fi
      fi
    else
      if [ "$committed" -eq 0 ]; then
        echo "Tidak ada perubahan file. Mengirim commit lokal ke origin/$branch..."
      fi
    fi
  else
    if [ "$committed" -eq 0 ]; then
      echo "Tidak ada perubahan file."
    fi
    echo "Peringatan: gagal mengambil data dari GitHub, mencoba push langsung."
  fi

  if git push -u origin "$branch"; then
    echo "Terkirim ke origin/$branch."
    echo "Repo GitHub sekarang sama dengan folder lokal."
    echo "Cloudflare Pages deploy otomatis sekitar 30-60 detik."
  else
    echo "Push gagal. Commit tetap tersimpan di lokal."
    return 1
  fi
}

_go_pull() {
  _go_safe
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Bukan folder git. Masuk ke folder proyek dulu: go nama"
    return 1
  fi

  local branch before behind pick stashed=0
  branch=$(git symbolic-ref --short -q HEAD) || {
    echo "Sedang detached HEAD. Pindah ke branch dulu: git switch main"
    return 1
  }
  before=$(git rev-parse --short HEAD)

  if [ -n "$(git status --porcelain)" ]; then
    echo "Ada perubahan belum di-commit:"
    git status --short
    echo
    echo " 1) simpan sementara (stash), lalu sinkron"
    echo " 2) commit dulu (go co), lalu sinkron"
    echo " 3) batal"
    read -r -p "Pilih: " pick
    case "$pick" in
      1)
        git stash push -u -q -m "go pull $(date '+%Y-%m-%d %H:%M')" || { echo "Stash gagal."; return 1; }
        stashed=1
        ;;
      2)
        _go_co || return 1
        ;;
      *)
        echo "Dibatalkan."
        return 0
        ;;
    esac
  fi

  if ! git fetch -q origin "$branch"; then
    echo "Gagal mengambil dari GitHub. Cek koneksi atau login."
    [ "$stashed" -eq 1 ] && git stash pop -q
    return 1
  fi

  behind=$(git rev-list --count "HEAD..origin/$branch")
  if [ "$behind" -eq 0 ]; then
    echo "Sudah up to date dengan origin/$branch."
  else
    if ! git pull -q --rebase origin "$branch"; then
      echo "Sinkron gagal (konflik). Selesaikan dulu, lalu: git rebase --continue"
      return 1
    fi
    echo "Diperbarui: $before -> $(git rev-parse --short HEAD) ($behind commit baru)"
    git diff --stat "$before" HEAD | tail -n 1
  fi

  if [ "$stashed" -eq 1 ]; then
    if git stash pop -q; then
      echo "Perubahan lokal dikembalikan dari stash."
    else
      echo "Perubahan lokal bentrok dengan versi terbaru. Cek: git status"
      echo "Stash masih tersimpan, lihat dengan: git stash list"
      return 1
    fi
  fi
  return 0
}

_go_clone() {
  _go_safe
  if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI (gh) belum terpasang. Pasang dulu: pkg install gh"
    return 1
  fi

  if ! gh auth status >/dev/null 2>&1; then
    echo "Belum login GitHub. Langkahnya:"
    echo "  1. Jalankan: gh auth login"
    echo "  2. Pilih: GitHub.com, lalu HTTPS, lalu Login with a web browser"
    echo "  3. Ikuti kode yang muncul di browser"
    echo "  4. Jalankan: gh auth setup-git"
    echo "Setelah itu ulangi: go clone"
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
    echo "Tidak ada repo ditemukan untuk akun ini."
    return 1
  fi

  echo "Repo GitHub kamu:"
  local k tag
  for k in "${!full[@]}"; do
    tag=""
    [ "${privs[$k]}" = "true" ] && tag=" (privat)"
    printf " %d) %s%s\n" $((k+1)) "${full[$k]##*/}" "$tag"
  done
  echo " q) batal"

  local ans t ok sel=()
  while true; do
    read -r -p "Pilih nomor (contoh: 3 atau 1 3 5): " ans
    [ "$ans" = "q" ] && return 0
    ok=1
    sel=()
    for t in $ans; do
      if [[ "$t" =~ ^[0-9]+$ ]] && [ "$t" -ge 1 ] && [ "$t" -le "${#full[@]}" ]; then
        sel+=("$t")
      else
        echo "Nomor tidak valid: $t"
        ok=0
        break
      fi
    done
    if [ "$ok" -eq 1 ] && [ ${#sel[@]} -gt 0 ]; then break; fi
    echo "Coba lagi, atau q untuk batal."
  done

  mkdir -p "$GO_ROOT"
  local idx repo name target last=""
  for idx in "${sel[@]}"; do
    repo="${full[$((idx-1))]}"
    name="${repo##*/}"
    target="$GO_ROOT/$name"
    if [ -e "$target" ]; then
      echo "Dilewati, folder sudah ada: $name"
      continue
    fi
    if gh repo clone "$repo" "$target" >/dev/null; then
      echo "Berhasil: $name"
      last="$target"
    else
      echo "Gagal clone: $name"
    fi
  done

  if [ ${#sel[@]} -eq 1 ] && [ -n "$last" ]; then
    cd "$last" && echo "Sekarang di: $PWD"
  elif [ -n "$last" ]; then
    echo "Proyek ada di $GO_ROOT. Buka dengan: go nama"
  fi
}

go() {
  case "$1" in
    "") _go_browse ;;
    help)
      echo "go              -> menu nomor (mulai dari Acode)"
      echo "go acode        -> folder Acode"
      echo "go nama         -> proyek di Acode / bookmark"
      echo "go new nama     -> buat proyek baru"
      echo "go clone        -> pilih repo GitHub dengan nomor, lalu clone"
      echo "go pull         -> ambil versi terbaru dari GitHub (dari folder proyek)"
      echo "go co [pesan]   -> add, commit, sinkron, push (dari folder proyek)"
      echo "go add nama     -> bookmark folder ini"
      echo "go list         -> daftar bookmark & proyek"
      echo "go del nama     -> hapus bookmark"
      echo "go ss | go home"
      ;;
    acode) cd "$GO_ROOT" || return 1 ;;
    ss) cd "$HOME/storage/shared" || return 1 ;;
    home) cd "$HOME" ;;
    co) shift; _go_co "$@" ;;
    pull) _go_pull ;;
    clone) _go_clone ;;
    new)
      [ -z "$2" ] && { echo "Pakai: go new nama"; return 1; }
      mkdir -p "$GO_ROOT/$2" && cd "$GO_ROOT/$2" && echo "Dibuat: $PWD"
      ;;
    add)
      [ -z "$2" ] && { echo "Pakai: go add nama"; return 1; }
      touch "$GO_BM"
      grep -v "^$2|" "$GO_BM" > "$GO_BM.tmp"
      echo "$2|$PWD" >> "$GO_BM.tmp"
      mv "$GO_BM.tmp" "$GO_BM"
      echo "Tersimpan: $2 -> $PWD"
      ;;
    del)
      [ -z "$2" ] && { echo "Pakai: go del nama"; return 1; }
      touch "$GO_BM"
      grep -v "^$2|" "$GO_BM" > "$GO_BM.tmp"
      mv "$GO_BM.tmp" "$GO_BM"
      echo "Dihapus: $2"
      ;;
    list)
      echo "Bookmark:"
      if [ -s "$GO_BM" ]; then sed 's/|/ -> /' "$GO_BM"; else echo "(kosong)"; fi
      echo "Proyek di Acode:"
      ls -1 "$GO_ROOT" 2>/dev/null || echo "(Acode tidak ditemukan)"
      ;;
    *)
      if [ -d "$GO_ROOT/$1" ]; then
        cd "$GO_ROOT/$1"
      else
        local p
        p=$(grep "^$1|" "$GO_BM" 2>/dev/null | head -1 | cut -d'|' -f2-)
        if [ -n "$p" ] && [ -d "$p" ]; then cd "$p"
        else echo "Tidak ditemukan: $1"; return 1
        fi
      fi
      ;;
  esac
}
