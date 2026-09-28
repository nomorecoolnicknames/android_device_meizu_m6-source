#!/system/bin/sh
# Build Station: bootdiag cache capture
OUT=/cache/bootdiag
VERSION=20260514-display-stack-v4
[ -d /cache ] || exit 0
mkdir -p "$OUT" 2>/dev/null || exit 0
TS="$(date +%Y%m%d-%H%M%S 2>/dev/null)"
if [ -z "$TS" ]; then
    TS="$(cat /proc/uptime 2>/dev/null | sed 's/ .*//' | tr . _)"
fi
[ -n "$TS" ] || TS=early
RUN="$OUT/run-${TS}-$$"
mkdir -p "$RUN" "$RUN/proc" "$RUN/sys" "$RUN/cmd" "$RUN/files" 2>/dev/null || exit 0
chmod 0777 "$OUT" "$RUN" 2>/dev/null
{
    echo "Build Station bootdiag $VERSION"
    echo "run=$RUN"
    echo "date=$(date 2>/dev/null)"
    echo "uptime=$(cat /proc/uptime 2>/dev/null)"
    echo "cmdline=$(cat /proc/cmdline 2>/dev/null)"
} > "$RUN/00_manifest.txt" 2>/dev/null
for f in "$OUT"/phase-*.txt; do
    [ -e "$f" ] || continue
    echo "--- $f" >> "$RUN/00_init_phases.txt"
    cat "$f" >> "$RUN/00_init_phases.txt" 2>/dev/null
    echo >> "$RUN/00_init_phases.txt"
done
log_kmsg() {
    echo "Build Station bootdiag: $1" > /dev/kmsg 2>/dev/null
}
copy_file() {
    [ -r "$1" ] || return 0
    dest="$RUN/$2"
    dir="${dest%/*}"
    [ "$dir" = "$dest" ] || mkdir -p "$dir" 2>/dev/null
    cat "$1" > "$dest" 2>/dev/null
}
copy_dir() {
    [ -d "$1" ] || return 0
    mkdir -p "$RUN/$2" 2>/dev/null || return 0
    cp -af "$1"/* "$RUN/$2"/ 2>/dev/null
}
capture_cmd() {
    name="$1"
    shift
    "$@" > "$RUN/cmd/$name" 2>&1
}
capture_sh() {
    name="$1"
    shift
    /system/bin/sh -c "$*" > "$RUN/cmd/$name" 2>&1
}
ensure_debugfs() {
    [ -d /sys/kernel/debug ] || mkdir -p /sys/kernel/debug 2>/dev/null
    grep -q " /sys/kernel/debug " /proc/mounts 2>/dev/null || mount -t debugfs debugfs /sys/kernel/debug 2>/dev/null
}
copy_debug_file() {
    [ -r "$1" ] || return 0
    dest="$RUN/$2"
    dir="${dest%/*}"
    [ "$dir" = "$dest" ] || mkdir -p "$dir" 2>/dev/null
    dd if="$1" of="$dest" bs=65536 count=16 2>/dev/null
}
capture_debug_tree() {
    label="$1"
    root="$2"
    [ -d "$root" ] || return 0
    mkdir -p "$RUN/debug/$label" 2>/dev/null || return 0
    find "$root" -maxdepth 2 -type f 2>/dev/null | sed -n '1,220p' | while read f; do
        [ -r "$f" ] || continue
        base="$(echo "$f" | sed 's#^/##; s#[^A-Za-z0-9._/-]#_#g; s#/#_#g')"
        case "$base" in *generate*|*trigger*|*oops*|*panic*|*sysrq*)
            echo "skip dangerous debugfs $f" >> "$RUN/00_manifest.txt"
            continue
            ;;
        esac
        copy_debug_file "$f" "debug/$label/$base.txt"
    done
}
log_kmsg "cache collection begin $RUN"
ensure_debugfs
copy_file /proc/cmdline proc/cmdline.txt
copy_file /proc/uptime proc/uptime.txt
copy_file /proc/version proc/version.txt
copy_file /proc/bootprof proc/bootprof.txt
copy_file /proc/interrupts proc/interrupts.txt
copy_file /proc/devices proc/devices.txt
copy_file /proc/modules proc/modules.txt
copy_file /proc/mounts proc/mounts.txt
copy_file /proc/partitions proc/partitions.txt
copy_file /proc/cgroups proc/cgroups.txt
copy_file /proc/meminfo proc/meminfo.txt
copy_file /proc/iomem proc/iomem.txt
copy_file /proc/diskstats proc/diskstats.txt
copy_file /proc/wakelocks proc/wakelocks.txt
copy_file /proc/wakeup_sources proc/wakeup_sources.txt
copy_file /proc/last_kmsg proc/last_kmsg.txt
copy_file /proc/ramoops proc/ramoops.txt
copy_file /proc/mtk_ram_console proc/mtk_ram_console.txt
copy_file /sys/class/android_usb/android0/state sys/usb_state.txt
copy_file /sys/class/android_usb/android0/functions sys/usb_functions.txt
copy_file /sys/devices/platform/battery_meter/FG_daemon_disable sys/FG_daemon_disable.txt
copy_dir /sys/fs/pstore pstore
copy_safe_proc_aed() {
    [ -d /proc/aed ] || return 0
    mkdir -p "$RUN/proc/aed" 2>/dev/null
    for f in /proc/aed/*; do
        [ -r "$f" ] || continue
        base="${f##*/}"
        case "$base" in
            generate*|*trigger*|*oops*|*panic*)
                echo "skip dangerous /proc/aed/$base" >> "$RUN/00_manifest.txt"
                continue
                ;;
        esac
        [ -f "$f" ] && copy_file "$f" "proc/aed/$base"
    done
}
copy_safe_proc_aed
if command -v dmesg >/dev/null 2>&1; then capture_cmd dmesg.txt dmesg; fi
if command -v getprop >/dev/null 2>&1; then
    capture_cmd getprop.txt getprop
    capture_sh props_boot_usb_services.txt "getprop | grep -E '^\[(init\.svc|sys\.usb|persist\.sys\.usb|persist\.mediatek|ro\.boot|ro\.hardware|debug\.|service\.)'"
fi
if command -v logcat >/dev/null 2>&1; then
    capture_cmd logcat_all.txt logcat -b all -d -v threadtime
    capture_cmd logcat_kernel.txt logcat -b kernel -d -v threadtime
fi
capture_cmd ps.txt ps
capture_cmd ps_A.txt ps -A
capture_cmd mount.txt mount
capture_cmd df.txt df
capture_sh by_name.txt "ls -l /dev/block/platform/*/*/by-name /dev/block/platform/*/by-name /dev/block/by-name 2>/dev/null"
capture_sh graphics_listing.txt "ls -lR /sys/class/graphics /sys/class/backlight /sys/class/leds 2>/dev/null"
capture_sh graphics_state.txt "for f in /sys/class/graphics/fb*/name /sys/class/graphics/fb*/modes /sys/class/graphics/fb*/state /sys/class/graphics/fb*/bits_per_pixel /sys/class/graphics/fb*/virtual_size /sys/class/backlight/*/brightness /sys/class/backlight/*/max_brightness /sys/class/leds/*/brightness /sys/class/leds/*/max_brightness; do [ -r "$f" ] && echo --- $f && cat "$f"; done"
capture_sh usb_state.txt "for f in /sys/class/android_usb/android0/* /sys/class/udc/*/state /sys/class/udc/*/function /sys/class/udc/*/is_selfpowered; do [ -r "$f" ] && echo --- $f && cat "$f"; done"
capture_sh usb_debug.txt "ls -lR /sys/class/android_usb /sys/class/udc /sys/bus/platform/drivers/*usb* /sys/bus/platform/drivers/*musb* 2>/dev/null"
capture_sh power_supply.txt "for f in /sys/class/power_supply/*/*; do [ -r "$f" ] && echo --- $f && cat "$f"; done"
capture_sh wakeup_debug.txt "cat /proc/wakelocks 2>/dev/null; cat /proc/wakeup_sources 2>/dev/null; cat /sys/kernel/debug/wakeup_sources 2>/dev/null"
capture_sh module_params.txt "for f in /sys/module/mtk*/parameters/* /sys/module/*disp*/parameters/* /sys/module/*usb*/parameters/* /sys/module/*fb*/parameters/* /sys/module/*lcm*/parameters/* /sys/module/*mali*/parameters/* /sys/module/*ged*/parameters/*; do [ -r "$f" ] && echo --- $f && cat "$f"; done"
capture_sh debugfs_index.txt "for d in /d /sys/kernel/debug /d/mtkfb /sys/kernel/debug/mtkfb /sys/kernel/debug/dispsys /d/dispsys /sys/kernel/debug/ged /d/ged /sys/kernel/debug/mali* /d/mali* /sys/kernel/debug/cmdq /d/cmdq /sys/kernel/debug/tracing /d/tracing; do [ -e "$d" ] && echo --- $d && ls -l "$d"; done"
capture_sh display_gpu_nodes.txt "ls -lR /dev/graphics /dev/dri /dev/mali* /dev/ion /dev/ged /dev/mtk_cmdq /dev/mtk_disp_mgr /dev/disp 2>/dev/null"
capture_sh sync_state.txt "cat /sys/kernel/debug/sync 2>/dev/null; cat /d/sync 2>/dev/null"
capture_sh display_stack_state.txt "cat /proc/mtkfb 2>/dev/null; dumpsys SurfaceFlinger 2>/dev/null; dumpsys gfxinfo 2>/dev/null"
capture_sh media_codec_state.txt "dumpsys media.codec 2>/dev/null; ls -l /system/etc/media_codecs*.xml /vendor/etc/media_codecs*.xml /system/lib*/libstagefright*avc* /vendor/lib*/libtinyxml.so 2>/dev/null"
copy_debug_file /sys/kernel/debug/sync debug/sync.txt
copy_debug_file /d/sync debug/d_sync.txt
copy_debug_file /sys/kernel/debug/tracing/trace debug/tracing_trace.txt
copy_debug_file /d/tracing/trace debug/d_tracing_trace.txt
capture_debug_tree ged /sys/kernel/debug/ged
capture_debug_tree d_ged /d/ged
capture_debug_tree mali /sys/kernel/debug/mali
capture_debug_tree d_mali /d/mali
capture_debug_tree mtkfb /sys/kernel/debug/mtkfb
capture_debug_tree d_mtkfb /d/mtkfb
capture_debug_tree dispsys /sys/kernel/debug/dispsys
capture_debug_tree d_dispsys /d/dispsys
capture_debug_tree cmdq /sys/kernel/debug/cmdq
capture_debug_tree d_cmdq /d/cmdq
capture_sh binder_state_head.txt "cat /sys/kernel/debug/binder/state 2>/dev/null | sed -n '1,1200p'"
ls -1dt "$OUT"/run-* 2>/dev/null | sed -n '13,$p' | while read old; do
    [ -n "$old" ] && rm -r "$old" 2>/dev/null
done
sync
chmod -R 0777 "$RUN" 2>/dev/null
log_kmsg "cache collection done $RUN"
exit 0
