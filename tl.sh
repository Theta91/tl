#!/bin/bash --

################################################################################
#The MIT License (MIT)
#
#Copyright (c) 2011-2014
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
################################################################################

################################################################################
#    User-defined Variables
# Separator between track number and track title. There is no other existing
# separation so don't forget to add whitespace.
sep=" "
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
if [[ -z $1 || $1 = "--help" || $1 = "-h" ]]
then
  echo -e "Usage:"
  echo -e "  tl [directory]\n"

  echo -e "tl generates a tracklist for a given directory of properly tagged FLAC files\n"
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
    samples[$c]=$(metaflac --show-total-samples "${files[$c]}")
    rate[$c]=$(metaflac --show-sample-rate "${files[$c]}")

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
  track_number[$c]=$(metaflac --list "${files[$c]}" | awk -F "=" 'tolower($0) ~ /tracknumber/ { print $2 }' | sed s/[^0-9]//)
  track_title[$c]=$(metaflac --list "${files[$c]}" | awk -F "=" 'tolower($0) ~ /title/ { print $2 }')
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
