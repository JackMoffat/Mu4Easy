#!/bin/bash

# Contains the functions to be run by setupMu4eAccount.sh.
# Functions contained in this file:
#
#   make_mbsyncpass
#   make_authinfo
#   get_foldernames
#   make_directories
#   assemble_channel_group
#   remove_email
#

function make_mbsyncpass {
    # creates and stores password for an account in .gpg encrypted file
    MBP=".mbsyncpass-${ACCOUNTPROVIDER}"
    ENTRY1=""; read -sp "Enter password for ${ACCOUNTPROVIDER}:" -s ENTRY1; echo -e "\n"
    ENTRY2=""; read -sp "confirm password for ${ACCOUNTPROVIDER}:" -s ENTRY2;  echo -e "\n"

    # confirm entries match or leave blank to exit
    if [[ -z "$ENTRY1" ]]; then
        echo "password not set, no file created"
    elif [[ ! -z $ENTRY1 ]] && [[ "$ENTRY1" == "$ENTRY2" ]]; then
        echo "password set"
        echo $ENTRY1 > "${MBP}"
        gpg2 -c "${MBP}"
        # clear password from variables
        # remove plain text file holding pasword
        ENTRY1=""; ENTRY2=""
        if [[ -f "${MBP}.gpg" ]]; then
            rm "${MBP}"
            echo -e "\n deleting plain text file"
        fi
    else
        echo -e "\nno password match, please try again or input blank password to exit\n"
        make_mbsyncpass
    fi
}


function make_authinfo {
    # creates or updates the .authinfo.gpg file that holds SMTP/IMAP server/port information for account
    # overwrite old .authinfo.gpg when finished to update

    # defaults - catch all option works for gmail accounts
    local SMTPSERVER SMTPPORT IMAPPORT
    SMTPPORT="587"
    IMAPPORT="993"
    case in
        *"outlook"*|"*uwaterloo*"|"*hotmail*")
            SMTPSERVER="smtp.office365.com"
            IMAPSERVER="outlook.office365.com"
            ;;
        *)
            SMTPSERVER="smtp.${PROVIDER}.com"
            IMAPSERVER="imap.${PROVIDER}.com"
            ;;
    esac

    if [[ -f ".authinfo.gpg" ]]; then
        echo "enter password to decrypt existing authinfo file"
        gpg2 --yes ".authinfo.gpg"
    fi
    # Display current port and server settings, give option to edit
    echo -e "the current settings to be written are: \n \n"
    echo -e "machine ${SMTPSERVER} login $ACCOUNT port ${SMTPPORT} password <password>\n"
    echo -e "machine ${IMAPSERVER} login $ACCOUNT port ${IMAPPORT} password <password>\n\n"
    read -p "do you want to change these values? y/n : " ANSWER
    echo -e "\n"
    while [[ true ]]; do
        if [[ $ANSWER == "y" ]]; then
            read -p "SMTP server: " SMTPSERVER 
            echo -e "\n"; read -p " SMTP port: " SMTPPORT
            echo -e "\n"; read -p "IMAP server: " IMAPSERVER
            echo -e "\n"; read -p "IMAP port: " IMAPPORT
            break
        elif [[ $ANSWER == "n" ]]; then
            break
        else
            echo "Please enter y or n"
            continue
        fi
    done

    # get password for email from .mbsyncpass
    # write new info to authinfo    
    # re-encrypt to .authinfo.gpg and clear passwords
    EMAILPASS="$(gpg2 -d ".mbsyncpass-${ACCOUNTPROVIDER}.gpg")"
    cat<<EOF>>".authinfo"
machine $SMTPSERVER login $ACCOUNT port $SMTPPORT password $EMAILPASS
machine $IMAPSERVER login $ACCOUNT port $IMAPPORT password $EMAILPASS
EOF
    echo -e "\n" >> ".authinfo"
    gpg2 -c ".authinfo"
    EMAILPASS=""
    rm $HOME/.emacs.d/mu4e/.authinfo

    # Display messages, make new symlink to home if one doesnt already exist
    if [[ ! -f $HOME/.authinfo.gpg ]]; then
        ln -s $HOME/.emacs.d/mu4e/.authinfo.gpg $HOME/.authinfo.gpg
        echo "Encrypted to .authinfo.gpg and made symlink in $HOME"
    else
        echo -e "Encrypted to .authinfo.gpg \n.authinfo.gpg file already found in \$HOME. Either ignore this message and overwrite it or \n move it and make a new symlink pointing to ${PWD}/authinfo.gpg"
    fi
}


function get_folder_names {
    # creates FOLDERLIST by initiating a sync for a given account and extracting folder names from output
    > $FOLDERLIST && echo "made $FOLDERLIST"
    echo -e "\n"

    # this call to mbsync is cut short after retrieving names of folders
    mbsync -c $HOME/.emacs.d/mu4e/${SYNCFILE} -Dmn "${ACCOUNTPROVIDER}" | while read -r line; do
        # Opening master box always comes after mail directories have finished being listed
        if [[ $line = *"Opening master box"* ]]; then
            exit
        fi
        # extract folder name only from returned line
        if [[ $line = *" LIST "* ]]; then
            echo -e $line | awk -F\"\/ '{print $NF}' | tr -d '"' | sed '/^[a-z A-Z]/!d' | sed -e 's/^[ \t]*//' >> $HOME/.emacs.d/mu4e/$FOLDERLIST
        fi
    done
}


function make_directories {
    # makes main folder for the account within mu4e/Maildir,
    # symlink ~/Maildir to mu4e/Maildir, if it doesnt exist already.
    # If a list of folders associated with the given email has been retrieved,
    # make mu-style directories from them within mu4e/Maildir
    
    mkdir -p $MAILHOME
    mu mkdir $MAILHOME
    if [[ ! -e "$HOME/Maildir" ]]; then ln -s $HOME/.emacs.d/mu4e/Maildir $HOME/Maildir; else
        echo -e "~/Maildir already found, please move the original and create symlink to ${PWD}/Maildir/ \n or ignore this if it is already symlinked "
    fi
    

    if [[ -f "$FOLDERLIST" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            mkdir -p "${MAILHOME}${line}"
            mu mkdir "${MAILHOME}${line}"
        done < $FOLDERLIST
    fi
}


function assemble_channel_group {
    # Called after channel templates written to .mbsyncrc
    # Groups all an account's channels in .mbsyncrc for simultaneous syncing under single call
    
    CHANNELS="Group ${ACCOUNTPROVIDER}"
    while IFS= read -r line; do
        if [[ $line != *"inbox" ]] && [[ $line != *"calendar" ]] && [[ $line = "Channel ${ACCOUNTPROVIDER}"* ]]; then
            CHANNELS="${CHANNELS}\n$line"
        fi
    done < $SYNCFILE

    # add tag to indicate end of accounts information in .mbsyncrc,
    # and some newlines
    CHANNELS="${CHANNELS}\n# End group ${EMAILADDRESS}" 
    echo -e "$CHANNELS" >> "${SYNCFILE}"
    for i in {1..4}; do
        echo -e "\n" >> "${SYNCFILE}"
    done
}


function remove_email {
    # takes ARG1 email address of account
    # ARG2 the name associated with account's .mbsyncpass and Maildir folder
    #    (example. "roberttables-gmail", from the key .mbsyncpass-roberttables-gmail and folder ~/Maildir/roberttables-gmail)
    # ARG3 the file where the lisp configuration for mu4e is stored (ex. email.org)
    # ARG4 leave blank or enter "DELETE FOLDER" to delete account's maildir folder

    # remove account .mbsyncpass
    # remove account information from .mbsyncrc
    # trim leading newlines from .mbsyncrc (if there are any) 
    # remove lisp config    
    rm ".mbsyncpass-${ACCOUNTPROVIDER}.gpg" && echo -e ".mbsyncpass-${ACCOUNTPROVIDER}.gpg removed "
    sed -i "/# Account Information for ${EMAILADDRESS}/,/# End group*/d" .mbsyncrc
    sed -i '/./,$!d' .mbsyncrc 
    sed -i "/(make-mu4e-context ;; ${EMAILADDRESS}/,/;;CONTEXTINSERTIONSITE/d" ${LISPCONFIGFILE}

    # delete folder associated with address. WARNING: may cause deletion of emails?
    # delete .mbsyncrc if empty
    if [[ $DELETEFOLDER == "DELETE FOLDER" ]]; then
        rm -rf "Maildir/${ACCOUNTPROVIDER}"
    fi
    echo -e "Information for ${EMAILADDRESS} removed from all except .authinfo.gpg"
    if grep --quiet "# Account Information for" .mbsyncrc; then
        exit
    else
        rm .mbsyncrc
    fi
    
}
