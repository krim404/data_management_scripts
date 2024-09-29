#!/bin/bash
LC_NUMERIC=C 
if [ $# -eq 0 ]; then
    echo "Error: This script requires the target as a parameter or first the source and then the target"
    echo "Usage: $0 <parameter>"
    exit 1
fi

convert_size() {
    local size=$1
    local units=("KB" "MB" "GB" "TB" "PB")
    local unit=0

    while (( $(echo "$size >= 1000" | bc -l) )); do
        
        size=$(echo "scale=3; $size / 1000" | bc -l)
        ((unit++))

    done

    #  Rounding to two decimal places
    size=$(printf "%.2f" $size)

    echo "$size ${units[$unit]}"
}

# Setting source and target directories
if [ $# -eq 1 ]; then
    SOURCE="./"
    DEST=${1%/}/
elif [ $# -eq 2 ]; then
    SOURCE=${1%/}/
    DEST=${2%/}/
fi

LOGFILE="${SOURCE}rsync_log.txt"
EXCLUDEFILE="/tmp/exclude_files_$$.txt"
touch "$EXCLUDEFILE"

if [ ! -d "$DEST" ]; then
    echo " Error: The target folder does not exist"
    exit 1
fi

if [ ! -d "$SOURCE" ]; then
    echo " Error: The source folder does not exist"
    exit 1
fi

if [ -f "$LOGFILE" ]; then
    # Add old transferred files to the exclusion list
    grep "^.* >f" "$LOGFILE" | awk '{print $NF}' | sed 's|^\./||' >> "$EXCLUDEFILE"

    # Remove duplicate entries from the exclusion list
    sort -u "$EXCLUDEFILE" -o "$EXCLUDEFILE"
fi

# Collect Metrics
EXCLUDE_LINES=$(wc -l < $EXCLUDEFILE | awk '{$1=$1};1')
SPEICHER=$(df -k "$DEST" | awk 'NR==2 {print $4}')
SPEICHER_H=$(convert_size "$SPEICHER")
RS_OUT=$(rsync -an --stats --exclude-from="$EXCLUDEFILE" "$SOURCE" "/tmp")
SPEICHER_REQ=$(grep "Total file size" <<< "$RS_OUT" | awk '{print $4}' | tr -d '.')
FILES_SYNC=$(grep "Number of files" <<< "$RS_OUT" | grep -q "(reg:" && { grep "Number of files" <<< "$RS_OUT" | awk '{print $6}' | tr -d '.,'; } || echo "0")
NUM_FILES=$(find "$SOURCE" -type f | wc -l | awk '{$1=$1};1')
SPEICHER_REQ=$((SPEICHER_REQ / 1000))
SPEICHER_REQ_H=$(convert_size $SPEICHER_REQ)
CALC_GESAMT=$(($EXCLUDE_LINES+$FILES_SYNC))

echo "Source: $SOURCE"
echo "Target: $DEST"
echo "Required / Free Storage: $SPEICHER_REQ_H / $SPEICHER_H"
echo "Number of Files: $NUM_FILES"
echo "Number of already transferred files: $EXCLUDE_LINES"
echo "Number of new files: $FILES_SYNC"
printf '%s\n' "$RS_OUT"
echo ""

if [ "$CALC_GESAMT" -ne "$NUM_FILES" ]; then
    DELETED=0
    # Difference detected. Check if files were simply deleted in the source
    while IFS= read -r filename; do
        # Check if file still exists
        if [ ! -e "${SOURCE}${filename}" ]; then
            echo "$filename" >> /tmp/deleted_$$
            ((DELETED++))
        fi
    done < "$EXCLUDEFILE"
    CALC_GESAMT_NUM=$(($NUM_FILES+$DELETED))
    echo "Number of already synchronized but deleted data: $DELETED (see /tmp/deleted_$$)"
    if [ "$CALC_GESAMT" -ne "$CALC_GESAMT_NUM" ]; then
        echo -e "\033[1;31mPOSSIBLE SYNC ERROR - NUMBER OF FILES DIFFERS FROM CALCULATION\033[0m"
        echo "Calculated: $CALC_GESAMT, Found: $NUM_FILES"
    fi
fi

if [ "$SPEICHER_REQ" -ge "$SPEICHER" ]; then
    echo -e "\033[1;31mWARNING - FREE STORAGE EXCEEDED\033[0m"
fi

if [ "$FILES_SYNC" -eq "0" ]; then
    echo -e "\033[1;31mWARNING - NOTHING TO DO\033[0m"
fi 


while true; do
    read -p "Do you want to continue (Y/N): " antwort
    case $antwort in
        [jJyY]* ) echo "Starting Sync"; break;;
        [nN]* ) echo "Abort"; exit;;
        * ) echo "Please answer with Y or N";;
    esac
done

# Remote Self and Logfile from Sync
echo "rsync_log.txt" >> $EXCLUDEFILE
echo "$0" >> $EXCLUDEFILE

# Execute rSync and create the logfile
rsync -av --log-file="$LOGFILE" --exclude-from="$EXCLUDEFILE" "$SOURCE" "$DEST"

# Delete temporary exclude file
rm "$EXCLUDEFILE"
if [ -f "/tmp/deleted_$$" ]; then
    rm "/tmp/deleted_$$"
fi

# Copy Logfile to target
cp "$LOGFILE" "$DEST"
