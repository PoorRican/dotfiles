#!/bin/bash

# TODO: accept config.ini for backup directories
# TODO: accept command line argument for backing up a specific top-level directory
# TODO: pause before backing up. Press Enter to continue

NAME="Backup Routine"
VERSION="0.1"

BACKUP_DIR="/Volumes/FIGS_HDD/backups"
CMD="rsync -trh --progress "
DIRS=(repos Documents Music dotfiles vimwiki)

# print name
echo "$NAME $VERSION"
echo

# if [[ !(-e $BACKUP_DIR/..) ]]; then
#     echo "Error: Destination unreachable"
#     exit 1
# fi
if [[ ! (-e $BACKUP_DIR) ]]; then
    echo "Creating backup directory..."
    mkdir $BACKUP_DIR
fi

# perform backups
echo "Starting Backups..."
# brute-force it...
$CMD ~/repos     $BACKUP_DIR/repos
$CMD ~/Documents $BACKUP_DIR/Documents
$CMD ~/Music     $BACKUP_DIR/Music
$CMD ~/dotfiles  $BACKUP_DIR/dotfiles
$CMD ~/vimwiki   $BACKUP_DIR/vimwiki

#for dir in $DIRS; do
    # echo $dir
    # DIR_PATH=$BACKUP_DIR/$dir
    # $CMD ~/$dir $DIR_PATH
    # echo "Completed $DIR_PATH"
#done
