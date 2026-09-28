#!/system/bin/sh

TAG="m6-data-space-guard"
MIN_FREE_KB=262144

log_kmsg() {
    echo "${TAG}: $*" > /dev/kmsg
}

data_free_kb() {
    set -- $(/system/bin/df -k /data 2>/dev/null | /system/bin/tail -n 1)
    [ "$6" = "/data" ] || return 0
    echo "$4"
}

prune_contents() {
    for dir in "$@"; do
        [ -d "$dir" ] || continue
        log_kmsg "prune contents of ${dir}"
        /system/bin/rm -rf "$dir"/* "$dir"/.[!.]* "$dir"/..?* 2>/dev/null
    done
}

fix_dalvik_dirs() {
    /system/bin/mkdir -p /data/dalvik-cache/arm /data/dalvik-cache/arm64
    /system/bin/chown root:root /data/dalvik-cache /data/dalvik-cache/arm /data/dalvik-cache/arm64
    /system/bin/chmod 0771 /data/dalvik-cache /data/dalvik-cache/arm /data/dalvik-cache/arm64
    /system/bin/restorecon /data/dalvik-cache /data/dalvik-cache/arm /data/dalvik-cache/arm64 2>/dev/null
}

log_top_data_dirs() {
    /system/bin/du -sk /data/* /data/.[!.]* 2>/dev/null | \
        /system/bin/sort -n | /system/bin/tail -20 | \
        while read size path; do
            log_kmsg "top-data ${size}KB ${path}"
        done
}

before="$(data_free_kb)"
[ -n "$before" ] || before=0

if [ "$before" -ge "$MIN_FREE_KB" ]; then
    log_kmsg "/data free ${before}KB; no cleanup needed"
    exit 0
fi

log_kmsg "/data low free ${before}KB; pruning runtime caches before zygote"
prune_contents \
    /data/dalvik-cache/arm \
    /data/dalvik-cache/arm64 \
    /data/resource-cache \
    /data/system/package_cache
fix_dalvik_dirs

after_cache="$(data_free_kb)"
[ -n "$after_cache" ] || after_cache=0
log_kmsg "/data free after cache prune ${after_cache}KB"

if [ "$after_cache" -ge "$MIN_FREE_KB" ]; then
    exit 0
fi

log_kmsg "/data still low; pruning volatile crash dumps"
prune_contents /data/anr /data/tombstones /data/core

after_crash="$(data_free_kb)"
[ -n "$after_crash" ] || after_crash=0
log_kmsg "/data free after crash-dump prune ${after_crash}KB"

if [ "$after_crash" -lt "$MIN_FREE_KB" ]; then
    log_kmsg "/data still below ${MIN_FREE_KB}KB; dumping largest top-level dirs"
    log_top_data_dirs
fi

exit 0
