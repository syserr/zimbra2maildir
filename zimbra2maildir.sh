#!/bin/bash

RENAME=prename

if [[ "$1" == "" || "$2" == "" ]]; then
   echo "Destination directory should not be live, move to the final location after it's built."
   echo "Pass 2 arguments:"
   echo "zimbra2maildir.sh <tgz-file> <dest-dir>"
   exit
fi

TGZFILE="$(realpath $1)"
DESTDIR="$(realpath $2)"

# If you want to put all your migrated folders into a folder
PRE=".MigratedMail"

echo "Creating $DESTDIR"
mkdir -p "$DESTDIR"
echo "Unpacking TGZ - $TGZFILE"
cd "$DESTDIR"
tar -xzf "$TGZFILE"
rm -rf Tags
echo "Number of emails $(find -name '*.eml' -print0 | grep -cz "^")"

echo "Consolidating directories"
cd "$DESTDIR"
find -type d -name '*!*' | while read sdir; do
    ddir="${sdir%%\!*}"
    find "$sdir" -type f -exec mv {} "$ddir" \;
    rmdir "$sdir"
done


echo "Rebase directories maildir spec"
# Moving directory in ./cur while we are at it, saves file moves
cd "$DESTDIR"
find . -depth -mindepth 1 -type d > dirlist.meta
cat dirlist.meta | while read d; do
    de=$(echo "$d" | sed 's/^\.//' | sed 's/\//./g')  # Removes first . and Converts / to dot
    de=$(echo $de | sed 's/[\!&,]/_/g') # Cleans up wacky characters
    mkdir "$PRE$de"
    #echo mv "$d" "$PRE$de/cur"
    mv "$d" "$PRE$de/cur"
    mkdir "$PRE$de"/{tmp,new}
done
if [[ "$PRE" != "" ]]; then
    mkdir -p $PRE/{cur,tmp,new}
fi

#'s/[^a-zA-Z0-9_\/\.]/_/g'

echo "Renaming .eml and .meta files with Perl $RENAME to clean up crazy filenames"
# I found even being an experienced sysadmin dealing with filenames with embedded tabs,
# among other things, was just too much.
#
# Zimbra amazes me, possible file name styles -- throwout any convention:
# 0000001234-This is my subject line.eml
# message-979.eml
# All sorts of special characters are apparently valid for a subect line in an email.
# Unicode in file names is awesome (inherited by the subject line) but what really
# takes firt place, is I kid you not, an embedded newline in the filename.

# Perl rename ($RENAME) helps totally obliterate weird characters
find -name '*.eml*' -print0 | $RENAME -0 --filename 's/[^a-zA-Z0-9_\/.]/_/g'

#find -name '*.eml' -print0 | $RENAME -0 's/-.*/-ZIMBRA.eml/'
#find -name '*.eml.meta' -print0 | $RENAME -0 's/-.*/-ZIMBRA.eml.meta/'


echo "Rename file according to maildir spec"
# Reference: https://cr.yp.to/proto/maildir.html
# This is spinning through all files (messages) and renamming things, no faster way
cd "$DESTDIR"
find -name '*.eml' | while read EFILE; do
    #echo "$EFILE"
    SUFFIX=""
    if [ -f "$EFILE.meta" ]; then
	if grep '"unread":0' "$EFILE.meta" > /dev/null; then
	    SUFFIX="S"
	fi
    fi
    mv "$EFILE" "${EFILE}:2,${SUFFIX}"
done

echo "Get rid of meta files, we no longer need them"
cd "$DESTDIR"
find -name '*.meta' -exec rm -f {} \;
echo "Number of emails $(find -name '*.eml*' -print0 | grep -cz "^")"

if [[ "$USER" == "root" ]]; then
    echo "Setting ownership to mail:mail on $DESTDIR"
    chown -R mail:mail "$DESTDIR"
    echo ""
    echo "Migration complete."
    echo "Move $DESTDIR/$PRE* to a location like /data/mail/data/domains/example.com/scott/Maildir/"
fi
