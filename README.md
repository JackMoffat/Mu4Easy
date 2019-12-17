# ( MU4EASY ): MU4E Automated Setup Yielder

These scripts are intended to automate and generalize the process outlined in this reddit post - [mu4e for dummies](https://www.reddit.com/r/emacs/comments/bfsck6/mu4e_for_dummies/)

Mu4e is an email client that enables access to multiple email addresses and their attachments via integration with emacs. The state of these accounts is maintained offline by isync, so you can access attachments and compose replies  without an active internet connection. 

Mu4e's text-based interface means that it imposes a lighter load on your computer's processing capacity, resulting in faster load times and a snappier UI. 



# Dependencies


## maildir-utils, synchronization, and encryption

The maildir-utils and mu4e packages are essential, and Isync is what allows us to keep copies of our email offline.


    sudo apt install maildir-utils mu4e isync 


Gnupg2 allows us to encrypt passwords instead of storing them as plain text files.


    sudo apt install gnupg2 gnutls-bin
    
(For those who are interested, Maildir-utils is the "Mu" in "Mu4e". The "4e" means "4 emacs" and the "4" in "4 emacs" represents the symbol 4's english homonym "for" which conveys the attribution of "e" ("emacs") to "Mu" ("Maildir-utils") Read all together, therefore, this acronym means "Maildir-Utils for emacs")


## Emacs configuration

### Folder Structure
- When customizing emacs, it is good to keep customizations and configurations in the folder **~/.emacs.d/**.
This script requires your main emacs config and init files to be stored in **~/.emacs.d**.
- If you don't have this folder, please create it now and move / delete the folder ".emacs", if it exists.
 - alternatively, if you have and want to keep an existing folder setup, create .emacs.d/ and make symlinks your config and init files inside of it.

Once you have setup .emacs.d, clone this repo as follows:

    git clone https://github.com/jackmoffat/mu4easy.git ~/.emacs.d/mu4e

 

### init.el and org-mode

emacs' init.el file is where customization usually starts, but it may not be where it should all remain. If you have several distinct activities you use emacs for, you may want to organize your customizations in a more legible format. *org-mode* files are great for this. To load a configuration file (ex. email.org), add the following lines to your init file.


    ;; converts org files to lisp, when corresponding org file is present
    
    (when (file-readable-p "~/.emacs.d/email.org")
        (org-babel-load-file (expand-file-name "~/.emacs.d/email.org")))
        
The format above can be used for any number of separate org files

# Use
    
To setup an email account for use with mu4e:

    cd ~/.emacs.d/mu4e

    chmod +x ./setupMu4eAccount.sh

    ./setupMu4eAccount.sh -A <emailaddress>


Then follow the prompts.

You will need information on the SMTP/IMAP ports and servers that your account uses to retrieve mail. These vary based on provider, some common settings have been included here.

Easiest thing to do is search for your provider's settings, ex. "outlook IMAP settings"

- [Common IMAP/SMTP settings](https://support.office.com/en-us/article/pop-and-imap-email-settings-for-outlook-8361e398-8af4-4e97-b147-6c6c4ac95353)

Some email providers will require you to enable IMAP connection to the account as a security measure. If you do a web search for "how to enable IMAP for <provider> account", it should be easy to find 

You will be asked to enter two kinds of password a few times during the setup, one for the email account being setup and one for encrypting/decrypting the .gpg files that hold the account's password. 

Passwords requested in the terminal generally refer to the password for the account being setup. If a password is asked for in a pop-up, it is usually to encrypt or decrypt a .gpg file. For example,

### In terminal

    Please enter your password: "1234"
    Please confirm password: "1234"


- `"1234"` refers to the account's actual password. It gets written in .mbsyncpass as plain text. You are then asked for `abcd` in a pop-up

### In Pop-up

    Enter passkey: "abcd"
    Confirm passkey: "abcd"


- `abcd` is the passkey you can use to decrypt the password stored in  a `*.gpg` file back into plain text.

# Lisp Configuration

This setup writes the lisp code that configures accounts within emacs to a file outside of init.el to keep the configuration files separate, but it can all be moved into whatever configuration file you like. I use **"email.org"** which is converted by org-babel into **"email.el"**.

## Removing an account

If you wish to remove an account:

    cd ~/.emacs.d/mu4e
    ./setupMu4eAccount.sh -R <emailaddress>
    
The account's STMP/IMAP information will remain in .authinfo.gpg after running this command, and this should be harmless. If you'd like to remove that too, just decrypt .authinfo.gpg, remove the relevant lines, and re-save it.


# Contribution

I am not a programmer by training. **Feel free to edit and improve this utility as you see fit**. 
If you have made a change you feel is worth sharing, please initiate a pull request. 

