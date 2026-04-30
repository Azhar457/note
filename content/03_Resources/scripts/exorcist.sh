#!/bin/bash
# =========================================================
# SCRIPT: THE SAFE EXORCIST v2.0
# Perbaikan: DCO reset, NVMe detect, mount check,
#            kernel refresh, HPA logic fix
# =========================================================

# ── ROOT CHECK ──────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo "❌ Jalankan sebagai root: sudo bash $0"
    exit 1
fi

# ── DEPENDENCY CHECK ────────────────────────────────────
for cmd in hdparm dd lsblk blockdev; do
    if ! command -v $cmd &>/dev/null; then
        echo "❌ Dependency tidak ditemukan: $cmd"
        echo "   Install: sudo dnf install hdparm util-linux coreutils"
        exit 1
    fi
done

echo "====================================================="
echo "🔪 DETEKSI HARDWARE LOKAL SAAT INI"
echo "====================================================="
lsblk -d -o NAME,SIZE,MODEL,VENDOR,TRAN,ROTA
# ROTA=1 berarti HDD, ROTA=0 berarti SSD/NVMe
echo "-----------------------------------------------------"
echo "⚠️  Jangan salah ketik! Pilih drive TARGET (bukan drive OS!)"
read -p "Masukkan NAMA DRIVE target (contoh: sdb, sdc): " TARGET_NAME
TARGET_DRIVE="/dev/$TARGET_NAME"

# ── FAIL-SAFE 1: Eksistensi Drive ───────────────────────
if [ ! -b "$TARGET_DRIVE" ]; then
    echo "❌ Batal: $TARGET_DRIVE tidak ditemukan!"
    exit 1
fi

# ── FAIL-SAFE 2: Cek apakah Drive Sedang Di-mount ───────
if mount | grep -q "^$TARGET_DRIVE"; then
    echo "❌ BATAL: $TARGET_DRIVE sedang ter-mount!"
    echo "   Jalankan: sudo umount ${TARGET_DRIVE}* lalu coba lagi."
    exit 1
fi

# ── FAIL-SAFE 3: Deteksi NVMe ───────────────────────────
IS_NVME=false
if echo "$TARGET_NAME" | grep -q "^nvme"; then
    IS_NVME=true
    echo ""
    echo "⚠️  Drive NVMe terdeteksi. hdparm tidak support NVMe."
    echo "   HPA/DCO tidak relevan untuk NVMe (protokol berbeda)."
    echo "   Akan langsung ke Zero-Fill menggunakan dd."
fi

# ── KONFIRMASI VISUAL ────────────────────────────────────
echo ""
echo "!!! ═══════════ PERINGATAN KRITIS ═══════════ !!!"
echo "Anda akan MENGHANCURKAN secara PERMANEN:"
echo "  • Semua partisi & data"
echo "  • HPA (Host Protected Area)"
echo "  • DCO (Device Configuration Overlay)"
echo "  • Bootkit / Rootkit / Virus apapun"
echo "Di drive:"
echo "-----------------------------------------------------"
lsblk -d -o NAME,SIZE,MODEL,SERIAL "$TARGET_DRIVE" 2>/dev/null || \
lsblk -d -o NAME,SIZE,MODEL "$TARGET_DRIVE"
echo "-----------------------------------------------------"
read -p "Ketik 'HANCURKAN' untuk konfirmasi: " CONFIRM
if [ "$CONFIRM" != "HANCURKAN" ]; then
    echo "🛡️  Dibatalkan. Aman."
    exit 0
fi

# ── LOG FILE ─────────────────────────────────────────────
LOGFILE="/tmp/exorcist_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1
echo "Log tersimpan di: $LOGFILE"
echo "Mulai: $(date)"

# ══════════════════════════════════════════════════════════
if [ "$IS_NVME" = false ]; then

    echo ""
    echo "[1/4] ═══ INTEROGASI DCO & HPA ═══"

    # Tampilkan info lengkap HPA
    echo "--- Output hdparm -N (HPA) ---"
    hdparm -N "$TARGET_DRIVE"

    # Tampilkan info DCO
    echo "--- Output hdparm --dco-identify (DCO) ---"
    hdparm --dco-identify "$TARGET_DRIVE" 2>/dev/null || \
        echo "ℹ️  Drive tidak support DCO atau DCO sudah bersih."

    echo ""
    echo "[2/4] ═══ RESET DCO LAYER (Lapisan Terbawah) ═══"
    # DCO harus direset SEBELUM HPA
    hdparm --dco-restore "$TARGET_DRIVE" 2>/dev/null && \
        echo "✅ DCO berhasil direset." || \
        echo "ℹ️  DCO tidak perlu direset atau tidak didukung."

    # Paksa kernel baca ulang geometri setelah DCO reset
    blockdev --rereadpt "$TARGET_DRIVE" 2>/dev/null || true
    sleep 1

    echo ""
    echo "[3/4] ═══ BUKA GEMBOK HPA ═══"

    # Ambil native max (angka setelah '/') dengan lebih aman
    HPA_LINE=$(hdparm -N "$TARGET_DRIVE" 2>/dev/null | grep -i "max sectors")
    echo "Raw output: $HPA_LINE"

    # Cek apakah HPA aktif
    if echo "$HPA_LINE" | grep -qi "HPA is enabled"; then
        NATIVE_MAX=$(echo "$HPA_LINE" | grep -oP '\d+/\K\d+')
        echo "🔍 HPA AKTIF! Native max: $NATIVE_MAX sektor"
        echo "   Membuka paksa HPA..."

        # p = persistent (survive power cycle)
        hdparm -N p"$NATIVE_MAX" "$TARGET_DRIVE"

        # Paksa kernel baca ulang ukuran disk
        blockdev --rereadpt "$TARGET_DRIVE" 2>/dev/null || true
        sleep 2

        echo "✅ HPA berhasil dibuka. Kapasitas penuh kini terlihat:"
        hdparm -N "$TARGET_DRIVE"

    elif echo "$HPA_LINE" | grep -qi "HPA is disabled"; then
        echo "✅ HPA sudah tidak aktif. Tidak perlu membuka."
    else
        echo "ℹ️  Tidak dapat menentukan status HPA. Lanjut ke Zero-Fill."
    fi

else
    echo "[1-3/4] NVMe — Skip DCO/HPA, langsung Zero-Fill."
fi

# ══════════════════════════════════════════════════════════
echo ""
echo "[4/4] ═══ ZERO-FILL (EXORCISM FINAL) ═══"
echo "      Menulis nol ke seluruh permukaan disk..."
echo "      Estimasi waktu: ~15-60 menit per 500GB (tergantung kecepatan drive)"
echo ""

# conv=noerror,sync → lanjut meski ada bad sector (penting untuk HDD rusak)
# bs=4M → chunk besar untuk kecepatan optimal
dd if=/dev/zero of="$TARGET_DRIVE" bs=4M conv=noerror,sync status=progress

EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ ═══════════════════════════════════════════"
    echo "   OPERASI SELESAI. Drive $TARGET_DRIVE suci."
    echo "   Log tersimpan: $LOGFILE"
    echo "   Selesai: $(date)"
    echo "═══════════════════════════════════════════"
else
    echo "⚠️  dd selesai dengan exit code $EXIT_CODE"
    echo "   Cek log untuk detail: $LOGFILE"
fi