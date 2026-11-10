# go-tools

Perintah `go` untuk mengelola proyek di folder Acode: pindah folder, sinkron dengan GitHub (`go co`, `go pull`), dan clone repo lewat menu nomor (`go clone`).

Berjalan di:
- Termux (Android)
- Alpine Linux (misalnya di dalam Acode)
- Ubuntu / Debian (misalnya dual boot)

## Install

### Termux dan Ubuntu / Debian

```
source <(curl -fsSL https://raw.githubusercontent.com/lptech22/go-tools/main/install.sh)
```

### Alpine

Jalankan `bash` dulu, karena installer dan `go` memakai bash:

```
bash
source <(curl -fsSL https://raw.githubusercontent.com/lptech22/go-tools/main/install.sh)
```

Installer akan memasang `bash`, `curl`, `git`, dan `gh` sesuai lingkungan. Setelah itu, perintah `go` langsung aktif di sesi tersebut.

## Yang dilakukan installer

1. Mengenali lingkungan (Termux, Alpine, atau Ubuntu/Debian).
2. Memasang paket yang belum ada (`curl`, `git`, `gh`; di Alpine ditambah `bash`).
3. Meminta izin penyimpanan HP. Hanya di Termux, dan cukup tekan **Izinkan** di pop-up.
4. Membuat folder Acode kalau belum ada.
5. Mengunduh `go` dan menambahkannya ke shell.
6. Login GitHub. Ikuti kode dan link yang muncul, cukup sekali.

Kalau sudah pernah install dan sudah login, langkah login akan dilewati.

## Lokasi folder Acode

| Lingkungan | Folder Acode |
|---|---|
| Termux | `~/storage/shared/Acode` |
| Android (Alpine di Acode) | `/storage/emulated/0/Acode`, kalau tersedia |
| Ubuntu / Debian | `~/Acode` |

Kalau folder sudah ada, tidak akan dibuat ulang.

## Setelah install

Perintah `go` langsung bisa dipakai. Kalau belum, tutup lalu buka lagi terminalnya, atau ketik `source ~/.bashrc`.

Untuk panduan lengkap, ketik:

```
go help
```

## Catatan per lingkungan

- **Termux:** izin penyimpanan wajib diberikan agar folder Acode bisa dipakai bersama aplikasi Acode.
- **Alpine:** kalau memakai shell lain (misalnya `ash`), jalankan `bash` dulu sebelum install.
- **Ubuntu / Debian:** `gh` harus tersedia di repositori apt. Kalau tidak, pasang manual dari https://cli.github.com lalu jalankan install ulang.

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
| `go ss` / `go home` | Ke folder penyimpanan / ke home |
| `go update` | Cek dan pasang versi terbaru |
| `go version` | Tampilkan versi |
| `go help` | Bantuan singkat |
| `c` | Bersihkan layar dan riwayat |
