# go-tools

Perintah `go` untuk Termux: pindah ke proyek di folder Acode, sinkron dengan GitHub (`go co`, `go pull`), dan clone repo lewat menu nomor (`go clone`).

## Install

```
source <(curl -fsSL https://raw.githubusercontent.com/lptech22/go-tools/main/install.sh)
```

Setelah selesai, perintah `go` langsung bisa dipakai.

## Setup awal (sekali)

Installer sudah mengurus semuanya: paket `curl`, `git`, dan `gh`, izin penyimpanan HP, dan login GitHub.

## Perintah

| Perintah | Fungsi |
|---|---|
| `go` | Menu pilih folder mulai dari Acode |
| `go nama` | Masuk ke proyek di Acode |
| `go lokasi` | Detail lokasi sekarang (path lengkap) |
| `go new nama` | Buat proyek baru |
| `go clone` | Pilih repo GitHub dengan nomor, lalu clone |
| `go pull` | Ambil versi terbaru dari GitHub |
| `go co [pesan]` | Commit semua perubahan dan push |
| `go add nama` / `go del nama` | Simpan atau hapus bookmark folder |
| `go list` | Daftar bookmark dan proyek |
| `go ss` / `go home` | Ke penyimpanan HP / ke home Termux |
| `go update` | Cek dan pasang versi terbaru |
| `go version` | Tampilkan versi |
| `go help` | Bantuan singkat |
| `c` | Bersihkan layar dan riwayat |

Folder proyek ada di `~/storage/shared/Acode`.
