#!/bin/sh

## usage: extract-files.sh $1 $2
## $1 and $2 are optional
## if $1 = image the files will be copied from the system image mounted at the folder specified by $2
## if $1 = unzip the files will be extracted from zip file (if $1 = anything else 'adb pull' will be used
## $2 specifies the folder where system image is mounted or zip file to extract from (default = ../../../${DEVICE}_update.zip)

VENDOR=meizu
DEVICE=meizu_m6
BLOB_LIST=proprietary-files-mtk.txt

if [ ! -f "$BLOB_LIST" ]; then
    BLOB_LIST=proprietary-files.txt
fi

BASE=../../../vendor/$VENDOR/$DEVICE/proprietary
rm -rf $BASE/*

if [ -z "$2" ]; then
    ZIPFILE=../../../${DEVICE}_update.zip
elif [ "$1" = "image" ]; then
    SRCDIR=$2
else
    ZIPFILE=$2
fi

trim_line() {
    echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

expand_entry() {
    case "$1" in
        *'{,64}'*)
            echo "$1" | sed 's/{,64}//g'
            echo "$1" | sed 's/{,64}/64/g'
            ;;
        *)
            echo "$1"
            ;;
    esac
}

pull_file() {
    FILE=$1
    OPTIONAL=$2
    DIR=`dirname "$FILE"`

    if [ ! -d "$BASE/$DIR" ]; then
        mkdir -p "$BASE/$DIR"
    fi

    if [ "$MODE" = "unzip" ]; then
        unzip -j -o "$ZIPFILE" "system/$FILE" -d "$BASE/$DIR"
        RC=$?
    elif [ "$MODE" = "image" ]; then
        if [ -f "$SRCDIR/$FILE" ]; then
            cp "$SRCDIR/$FILE" "$BASE/$FILE"
            RC=$?
        else
            RC=1
        fi
    else
        adb pull "/system/$FILE" "$BASE/$FILE"
        RC=$?
    fi

    if [ "$RC" != "0" ]; then
        if [ "$OPTIONAL" = "true" ]; then
            echo "optional blob missing: $FILE"
        else
            echo "missing blob: $FILE"
        fi
    fi
}

if [ "$1" = "unzip" -a ! -e "$ZIPFILE" ]; then
    echo "$ZIPFILE does not exist."
else
    MODE=$1
    while IFS= read -r LINE || [ -n "$LINE" ]; do
        SPEC=`trim_line "${LINE%%#*}"`
        [ -z "$SPEC" ] && continue

        OPTIONAL=false
        case "$SPEC" in
            -*)
                OPTIONAL=true
                SPEC=${SPEC#-}
                ;;
        esac

        SRC=${SPEC%%:*}
        for FILE in `expand_entry "$SRC"`; do
            pull_file "$FILE" "$OPTIONAL"
        done
    done < "$BLOB_LIST"
fi
./setup-makefiles.sh
