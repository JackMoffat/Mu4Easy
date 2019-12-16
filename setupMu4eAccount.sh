#!/bin/bash


# This script will  add or remove an account from mu4e. This is meant to be run from the .emacs.d directory
#   use -A <email> to add an account
#   use -R <email> to remove an account

source $HOME/.emacs.d/mu4e/setupMu4eFunctions.sh && source $HOME/.emacs.d/mu4e/setupMu4eTemplates.sh

while getopts ":A:" opt; do

    # create variables for use in script from email address 
    EMAILADDRESS="${OPTARG}"
    ADDRESS="${EMAILADDRESS#*@}"
    ACCOUNT="${EMAILADDRESS%@*}"
    PROVIDER="$(echo "${ADDRESS}" | sed 's/\.[^.]*$//' | sed 's/.*\.//')"
    ACCOUNTPROVIDER="${ACCOUNT}-${PROVIDER}"
    MAILHOME="Maildir/$ACCOUNTPROVIDER/"
    FOLDERLIST="${ACCOUNTPROVIDER}-folders"
    SYNCFILE=".mbsyncrc" 

    case $opt in
        A)
            ##################
            # Add an account #
            ##################
            
            # make GPG key from password for account, store in .emacs.d/mu4e/ 
            # make .authinfo.gpg, store in .emacs.d/mu4e and symlink to home
            make_mbsyncpass
            make_authinfo 

            # insert basic inbox template for account into SYNCFILE
            # Make basic inbox directory for account
            template_main_INBOX
            make_directories

            # use SYNCFILE to query account's mailserver to create FOLDERLIST
            # add a channel for each entry in FOLDERLIST to SYNCFILE
            get_folder_names

            while read -r line; do
                if [[ $line != "*INBOX*" ]]; then
                    echo $line | template_make_channel
                fi
            done < $FOLDERLIST

            # use FOLDERLIST to create subdirectory structure of Maildir/ACCOUNTPROVIDER 
            make_directories

            # create email.org (or .el) from emailBase.org and insert account's "context info" 
            template_make_lisp_context

            #remove folderlist
            # delete the grouping lines that were used to retrieve FOLDERLIST
            rm $FOLDERLIST
            sed -i '/#Remove these after first sync/,+2d' .mbsyncrc

            # Group all account's channels together in .mbsyncrc
            # sync all accounts listed in .mbsyncrc
            assemble_channel_group
            mbsync -c $HOME/.emacs.d/mu4e/.mbsyncrc -a
            # TODO fix automatic hotkey picking for switch-contexts for
            # accounts starting with the same letter in MU4ENAME
            ;;
        R)
            #####################
            # Remove an account #
            #####################
            read -p "Please enter the name of the file holding the account's lisp configuration information (ex. email.org)" LISPCONFIGFILE
            read -p "If you would like to delete the local folders associated with this account as well, please enter \"DELETE FOLDER\" now. \nleave blank to keep local folders" DELETEFOLDER
            remove_email 
            ;;
        *)
            echo "Please enter -A <email> to add an account, or -R <email> to remove an account"
            exit 1
            ;;
    esac            
done            
