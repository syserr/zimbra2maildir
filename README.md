# zimbra2maildir
Converts a Zimbra backup to maildir format

## Reason
Since owners of Zimbra don't seem to want to play with the Open Source community, I decided I better not wait around an longer and just move off.  It was a good run, I think I ran Zimbra for over 10 years just for personal email -- friends and family.  Migration is needed.

## Dragon slaying
Zimbras backup is generated with something like this on the Zimbra server:
```
/opt/zimbra/bin/zmmailbox -z -t 0 -m "bob@example.com" getRestURL -u "https://m.example.com" "//?fmt=tgz" > bob.tgz
```
There isn't **too much to do** to make the files inside into proper maildir-style files.  But the naming on these files is absolutely horrible!
```
Inbox/0000001726-Fwd_ Login - Allen Caves - Equipment.eml.meta
Inbox/0000001726-Fwd_ Login - Allen Caves - Equipment.eml
```
So some index number + the subject line.  Cool, what could go wrong?  Well a subject line seems to be able to have anything!  The obvious are emojis and unicode characters.  The best was a subject with a \n newline character in it.  So, your file names have all that -- **I'd never seen a filename with a new line character in the middle of it.**  Shell scripts just don't like crazy file names, sure "real" languages could handle this a little better.  This was going to be a 1 evening sort of script that turned into a weekend -- that's why I'm sharing my work.

## Requirements
The `rename` program that is popular on Linux distributions.  On Debian this is `file-rename` from the `rename` package, written by Larry Wall.  There is a similar rename out there, maybe a fork, that I didn't like as well -- don't use it.

## Example
```
# ./zimbra2maildir.sh bob.tgz bob
Creating /home/scott/bob
Unpacking TGZ - /home/scott/bob.tgz
Number of emails 112326
Consolidating directories
Rebase directories maildir spec
Renaming .eml and .meta files with Perl prename to clean up crazy filenames
Rename file according to maildir spec
Get rid of meta files, we no longer need them
Number of emails 112326
Setting ownership to mail:mail on /home/scott/bob

Migration complete.
Move /home/scott/bob/.MigratedMail* to a location like /data/mail/data/domains/example.com/bob/Maildir/
```






