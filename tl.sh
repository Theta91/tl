#!/bin/bash

################################################################################
#    Copyright (C) 2011 Someone
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

################################################################################
#    User-defined Variables
# Separator between track number and track title. There is no other existing
# separation so don't forget to add whitespace.
sep=" - "
# BB Code to apply to track number. Can be empty.
no="[b]"
nc="[/b]"
# Display track length. 0 (false, default until fixed) or 1 (true)
display_length=0
# BB Code to apply to track length. Can be empty. Not used when display_length
# is set to false.
to="[i]"
tc="[/i]"
################################################################################
#    Program-defined Variables (don't touch)
version="0.1"
################################################################################

print_help() {
  echo -e "Usage:"
  echo -e "  tl [options] [directory]"
  echo -e "  tl \n"

  echo -e "tl generates a tracklist for a given directory of properly tagged FLAC files\n"

  echo -e "Options:"
  echo -e "  -h  --help\t\tPrint this help and exit"
  echo -e "  -t  --total-length\tPrint total length of tracks in directory and exit (requires display_length set to true)"
  echo -e "  -v  --version\t\tPrint version and exit"
}

if [[ -z "$1" || "$1" = "--help" || "$1" = "-h" ]]
then
  print_help
  exit 0
fi

if [[ "$1" = "--version" || "$1" = "-v" ]]
then
  echo -e "tl ${version}"
  exit 0
fi

################################################################################
# Check to see whether the supplied directory is valid
if [[ ! -d "${!#}" || -h "${!#}" ]]
then
 echo -e "Directory does not exist or is a symbolic link. For help, use 'tl --help'"
 exit 1
fi

cd "${!#}"

################################################################################
# Populates an array with the list of files in the directory
files=( *flac )

# Grab number of items in array
items=${#files[*]}

# Calculate track length
if [[ $display_length -eq 1 ]]
then
  c=0
  total_length=0
  while [[ $c -lt $items ]]
  do
    samples[$c]=`metaflac --list "${files[$c]}" | awk -F ":" '/total[ _-]samples/ { print $2 }' | sed s/[^0-9]//g`
    rate[$c]=`metaflac --list "${files[$c]}" | awk -F ":" '/sample[ _-]rate/ { print $2 }' | sed s/[^0-9]//g`

    track_length[$c]=$(( ${samples[$c]} / ${rate[$c]} ))

    if [[ $1 = "-t" || $1 = "--total-length" ]]
    then
      total_length=$(( $total_length + ${track_length[$c]} ))
    fi

    m[$c]=$(( ${track_length[$c]} / 60 ))
    # Seconds are a somewhat nebulous problem. This returns an integer, so if you have
    # a total number of samples that is not evenly divisible by the sample rate (usually
    # 44100 Hz), then those extra samples aren't accounted for in the run time. [I think]
    # mpd always accounts for them when determining track length, but other media players,
    # such as vlc, do not.

    # The current behavior is to disregard the extra samples.
    s[$c]=$(( ${track_length[$c]} % 60 ))

    (( c++ ))
  done; c=0
fi

# Displays total length of files in directory and exits
if [[ ( $1 = "-t" || $1 = "--total-length" ) && $display_length -eq 0 ]]
then
  echo -e "display_length must be set to 1 in order to calculate total length. For help,"
  echo -e "use 'tl --help'"
  exit 1
elif [[ ( $1 = "-t" || $1 = "--total-length" ) && $display_length -eq 1 ]]
then
  total_m=$(( $total_length / 60 ))
  total_s=$(( $total_length % 60 ))
  printf "Total Length: %02d:%02d\n" $total_m $total_s
  exit 0
fi

# Stores track number and title
while [[ $c -lt $items ]]
do
  track_number[$c]=`metaflac --list "${files[$c]}" | awk -F "=" 'tolower($0) ~ /tracknumber/ { print $2 }' | sed s/[^0-9]//g`
  track_title[$c]=`metaflac --list "${files[$c]}" | awk -F "=" 'tolower($0) ~ /title/ { print $2 }'`
  (( c++ ))
done; c=0

# Displays tracklist
while [[ $c -lt $items ]]
do
  if [[ $display_length -eq 1 ]]
  then
    printf "${no}%02d${nc}${sep}%s ${to}(%02d:%02d)${tc}\n" $(( 10#${track_number[$c]} )) "${track_title[$c]}" ${m[$c]} ${s[$c]}
  else
    printf "${no}%02d${nc}${sep}%s\n" $(( 10#${track_number[$c]} )) "${track_title[$c]}"
  fi
  (( c++ ))
done; c=0
