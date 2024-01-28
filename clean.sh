#!/bin/bash
# Define the list of strings to check for at the beginning of file names
string_list=("private","image")

# Define the list of strings to check anywhere
string_list_any=("720p")

# Define unnecessary files
remove_files=("nfo","url","sfv")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[33m'
BLUE='\033[34m'
NC='\033[0m' # No Color

if [ $# -eq 0 ]; then
    echo "Usage: $0 <directory>"
    exit 1
fi

# Required Commands
commands=("mkvpropedit" "atomicparsley")

# Function to check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: '$1' command not found. Aborting."
        exit 1
    fi
}

# Check each command in the list
for cmd in "${commands[@]}"; do
    check_command "$cmd"
done

# Simple "is array unique" function
function is_array_unique() {
    local array=("$@")
    local length=${#array[@]}
    for ((i=0; i<$length; i++)); do
		str1="${array[i],,}"
        for ((j=i+1; j<$length; j++)); do
			str2="${array[j],,}"
			if [ "$str1" == "$str2" ]; then
                echo "Array contains duplicate entries ${array[i]}"
                return 1
            fi
        done
    done
    return 0
}

# Escape characters with special meaning in sed
escape_for_sed() {
    escaped_string=$(echo "$1" | sed 's/[][\/$*.^|]/\\&/g')
    echo "$escaped_string"
}

# Just print a warn message if some elements are in there multiple times
is_array_unique "${string_list[@]}"
is_array_unique "${string_list_c[@]}"

# Function to process files in a directory
process_file()
{
    local file="$1"
    prif=""
    org=$file
    # Überprüfe, ob der String den gewünschten Syntax hat
    if [[ $file =~ ^S[0-9]{2}E[0-9]{2}[\.-] ]]; then
        prif=$(echo "$file" | sed -nE 's/.*(S[0-9]{2}E[0-9]{2}).*/\1/p')
        prif="$prif-"
        file=$(echo "$file" | sed -E 's/S[0-9]{2}E[0-9]{2}[\.-]//')
    elif [[ $file =~ ^S[0-9]{2}E[0-9]{3}[\.-] ]]; then
            prif=$(echo "$file" | sed -nE 's/.*(S[0-9]{2}E[0-9]{3}).*/\1/p')
            prif="$prif-"
            file=$(echo "$file" | sed -E 's/S[0-9]{2}E[0-9]{3}[\.-]//')
    fi
    
    # Check if the file name starts with any of the specified prefixes
    for prefix in "${string_list[@]}"; do
        if [[ "${file,,}" =~ ^"${prefix,,}"[._-]. || "${file,,}" =~ ^"${prefix,,} " || ( "${prefix: -1}" == "]" && "${file,,}" =~ ^"${prefix,,}") ]]; then
            new_name=""
            if [[ "${prefix: -1}" == "]" ]]; then
                escaped_string=$(escape_for_sed "$prefix")
                new_name=$(echo "$file" | sed -e "s/^${escaped_string}//i")
            else
                new_name=$(echo "$file" | sed -e "s/^${prefix}[._-]//i" -e "s/^${prefix} //i")
            fi
            if [[ -n "${new_name}" && "$new_name" == *.* ]]; then
                # Rename the file
                mv "$org" "$prif$new_name"
                echo -e "${RED}Renamed: ${NC}$org to $prif$new_name"
                file="$prif$new_name"
                org="$file"
            fi
        fi
    done
    file=$org
    
    for anythi in "${string_list_any[@]}"; do
        if echo "$file" | grep -iq "$anythi"; then
            new_name=$(echo "$file" | sed "s/$anythi//gi")
            if [[ -n "$new_name" && "$new_name" == *.* ]]; then
                echo -e "${RED}Renamed: ${NC}$file to $new_name"
                mv "$file" "$new_name"
                file="$new_name"
            fi
        fi
    done
    
    filename="${file%.*}"
    file_extension="${file##*.}"
    
    for suffix in "${string_list[@]}"; do 
        if [[ "${filename,,}" =~ [._-]"${suffix,,}"$ || "${filename,,}" == *" ${suffix,,}" || ( "${suffix: -1}" == "]" && "${filename,,}" == *"${suffix,,}") ]]; then
            # Remove text at the end of the string (case-insensitive)
            new_name=""
            if [[ "${suffix: -1}" == "]" ]]; then
                escaped_string=$(escape_for_sed "$suffix")
                new_name=$(echo "$filename" | sed -e "s/${escaped_string}$//I")
            else
                new_name=$(echo "$filename" | sed -e "s/[._-]${suffix}$//I" -e "s/ ${suffix}$//I")
            fi
            if [[ -n "$new_name" ]]; then
                # Rename the file
                mv "$file" "$new_name.$file_extension"
                echo -e "${RED}Renamed: ${NC}$file to $new_name.$file_extension"
                file="$new_name.$file_extension"
            fi
        fi
    done
	
    filename="${file%.*}"
    trimmed_filename=$(echo "$filename" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [ "$file" != "$trimmed_filename.$file_extension" ]; then
        echo "Found Whitespaces in $file - Trimming"
        mv "$file" "$trimmed_filename.$file_extension"
        file="$trimmed_filename.$file_extension"
    fi
    
	  # Make sure the meta information Last Change will stay the same
	  original_mtime=$(stat -f %m "$file")

    # Part of the script to delete unneccessary files
    if [[ " ${remove_files[@]} " =~ " ${file_extension} " ]]; then
        echo "Deleting unneccessary file: $file"
        rm "$file"
	  elif [ "$file_extension" = "mp4" ]; then
		  metadata=$(atomicparsley "$file" -t 2>&1)
		  title=$(echo "$metadata" | awk -F 'contains:' '/©nam/ {print $2}')

		  if [ -n "$title" ]; then
			  title=$(echo "$title" | awk '{gsub(/^[ \t]+|[ \t]+$/,"")} {print}')
		  else
		      title=""
		  fi
		
		  if [ "$title" != "$filename" ]; then
			  echo -ne "${GREEN}Writing MP4 title original ${NC} \"$title\" to $filename"
			  atomicparsley "$file" --title "$filename" --overWrite > /dev/null
        if [ $? -eq 0 ]; then
            echo " SUCCESS"
        else
            echo -e " ${RED}FAILURE${NC}"
        fi 
			  touch -m -t "$(date -r "$original_mtime" "+%Y%m%d%H%M.%S")" "$file"
		  fi
		
    elif [ "$file_extension" = "mkv" ]; then
		  title=$(mediainfo --Output=JSON "$file" | jq -r '.media.track[0].Title')
		  # Check if the "title" field is present in the metadata
		  if [ -n "$title" ] && [ "$title" != "null" ]; then
			  :
		  else
			  title=""
		  fi
		
		  if [ "$title" != "$filename" ]; then
			  echo -ne "${GREEN}Writing MKV title original ${NC} \"$title\" to $filename"
			  mkvpropedit "$file" --edit info --set "title=$filename" > /dev/null 
        if [ $? -eq 0 ]; then
          echo " SUCCESS"
        else
          echo -ne "${RED} File error - Tryint to repair: ${NC}"
          mkvmerge -o "repair_$file" "$file" > /dev/null 
          if [ $? -eq 0 ]; then
             echo "SUCCESS"
             rm "$file"
             mv "repair_$file" "$file"
             mkvpropedit "$file" --edit info --set "title=$filename" > /dev/null 
          else
             echo "Failed"
             rm "repair_$file"
          fi

        fi
			  touch -m -t "$(date -r "$original_mtime" "+%Y%m%d%H%M.%S")" "$file"
		  fi
	fi
	
  if [ ! -s "$file" ]; then
    echo -e "WARNING ${BLUE} "$file" is empty${NC}"
  fi
}

# Process a directory
process_directory() {
    local dir="$1"
    cd "$dir" || exit 1

    # Loop through files in the current directory
    for file in *; do
        if [ -f "$file" ]; then
            process_file "$file"
        elif [ -d "$file" ]; then
            # Recursively process subdirectories
            process_directory "$dir/$file"
        fi
    done
    cd ..
}

# Start the script
for param in "$@"; do
	if [ -d "$param" ]; then
		process_directory "$param" 2>&1
    elif [ -f "$param" ]; then
        dir=$(dirname "$param")
        filename=$(basename "$param")
        cd "$dir"
        process_file "$filename" 2>&1
    else
	echo -e "${YELLOW}param $param ist not valid${NC}"
    fi
done
