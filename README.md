# go-tools

Perintah `go` untuk Termux: pindah ke proyek di folder Acode, sinkron dengan GitHub (`go co`, `go pull`), dan clone repo lewat menu nomor (`go clone`).

## Install

```
curl -fsSL https://raw.githubusercontent.com/lptech22/go-tools/main/install.sh | bash
```

Lalu tutup dan buka Termux lagi.

## Setup awal (sekali)

1. `termux-setup-storage` lalu izinkan akses penyimpanan
2. `git config --global user.name "nama"` dan `git config --global user.email "email"`
3. `pkg install gh`, lalu `gh auth login`, lalu `gh auth setup-git`

## Perintah

| Perintah | Fungsi |
|---|---|
| `go` | Menu pilih folder mulai dari Acode |
| `go nama` | Masuk ke proyek di Acode |
| `go new nama` | Buat proyek baru |
| `go clone` | Pilih repo GitHub dengan nomor, lalu clone |
| `go pull` | Ambil versi terbaru dari GitHub |
| `go co [pesan]` | Commit semua perubahan dan push |
| `go add nama` / `go del nama` | Simpan atau hapus bookmark folder |
| `go list` | Daftar bookmark dan proyek |
| `go ss` / `go home` | Ke penyimpanan HP / ke home Termux |
| `go help` | Bantuan singkat |

Folder proyek ada di `~/storage/shared/Acode`.
