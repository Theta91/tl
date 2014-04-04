tl is a command-line utility for generating a tracklist given a directory
containing an album in FLAC format.

To use tl, you must have flac installed.

Usage follows the form:
./tl.sh /path/to/directory/

There are some user-defined variables; they are found at the top of the script:
sep:
    The separator between the track number and the track title. There is no
    whitespace present, so that must be included. Default is " - ".
no & nc:
    The opening and closing BBCode to apply to the track number. It can be left
    empty. Default is bolding.
display_length:
    Whether or not to display track length at the end of the tracklist. Must be
    changed to 1 (true) if you wish to make use of the -t option. Default is 0
    (false).
to & tc:
    The opening and closing BBCode to apply to the track length. It can be left
    empty. Default is italics.
