#!/bin/bash

# Templates for most calls to cat to insert chunks of text.
# Functions contained in this file:
#
#   template_main_INBOX
#   template_make_channel
#   template_main_email_config
#   template_make_lisp_context
#

function template_main_INBOX {
    # adds main information for account to .mbsyncrc

    cat <<EOF >> "${SYNCFILE}"
# Account Information for $EMAILADDRESS
IMAPAccount $ACCOUNTPROVIDER
# Address to connect to
Host $IMAPSERVER
User $EMAILADDRESS
PassCmd "gpg2 -q --for-your-eyes-only --no-tty -d ~/.emacs.d/mu4e/.mbsyncpass-$ACCOUNTPROVIDER.gpg"
AuthMechs LOGIN
SSLType IMAPS
SSLVersions TLSv1.2
CertificateFile /etc/ssl/certs/ca-certificates.crt

# Local and remote storage
IMAPStore $ACCOUNTPROVIDER-remote
Account $ACCOUNTPROVIDER

# Main local storage for account, used to query server for subfolders
MaildirStore $ACCOUNTPROVIDER-local
Path ~/Maildir/$ACCOUNTPROVIDER/
Inbox ~/Maildir/$ACCOUNTPROVIDER/INBOX
Subfolders Verbatim

# Specify connection
Channel $ACCOUNTPROVIDER-inbox
Master :$ACCOUNTPROVIDER-remote:
Slave :$ACCOUNTPROVIDER-local:
Patterns "INBOX"
Create Both
Expunge Both
SyncState *

#Remove these after first sync
Group $ACCOUNTPROVIDER
Channel $ACCOUNTPROVIDER-inbox

EOF

    for i in {1..4}; do
        printf "\n" >> $SYNCFILE
    done
}



function template_make_channel {
    # Adds entries to .mbsyncrc based on lines in FOLDERLIST
    
    #format channel's name for mu4e buffer
    CHANNELENTRY=$(echo $line | tr '[:upper:]' '[:lower:]' | sed -e 's/ \/*/-/g')
    
    cat<<EOF>>"${SYNCFILE}"
Channel $ACCOUNTPROVIDER-$CHANNELENTRY
Master :$ACCOUNTPROVIDER-remote:"$line"
Slave :$ACCOUNTPROVIDER-local:"$line"
Create Both
Expunge Both
SyncState *
EOF

    for i in {1..2}; do
        printf "\n" >> $SYNCFILE
    done
}


function template_main_email_config {
    # This creates the main lisp configuration file for mu4e within emacs
    # recommended name: email.org
    # Will overwrite any existing file with the same name as LISPCONFIGFILE once set
    # (highly) recommended to use .org extension, so long as your org-babel can tangle

    
    read -p $'Enter name for file that will hold all lisp configuration info (ex. email.org)\n .org extension highly recommended): ' LISPCONFIGFILE    
    cat<< 'EOF' > "${LISPCONFIGFILE}"


#+STARTUP: here's startup
#+TITLE: Jack's semi-automated take on Mu4e for Dummies
#+CREATOR: u/skizmi, Jack M, reddit, google.
#+LANGUAGE: en
#+OPTIONS: num:nil
#+ATTR_HTML: :style margin-left: auto; margin-right: auto;




* Mu4e config

The vast majority of this configuration was written [[https://www.reddit.com/r/emacs/comments/bfsck6/mu4e_for_dummies/][on reddit]] by u/skizmi.

I have rewritten the configuration to work with a set of functions that [[https://github.com/jackmoffat/mu4easy][simplify the setup of mu4e]]. 

** basic config
#+BEGIN_SRC emacs-lisp
    (use-package org-mime
      :ensure t)

    (add-to-list 'load-path "/usr/share/emacs/site-lisp/mu4e/")


    (use-package mu4e
      :after (org-mime)
      :config
      (setq mu4e-maildir (expand-file-name "~/Maildir"))

                                            ; get mail
      (setq mu4e-get-mail-command "mbsync -c ~/.emacs.d/mu4e/.mbsyncrc -a"
            ;; mu4e-html2text-command "w3m -T text/html" ;;using the default mu4e-shr2text
            mu4e-view-prefer-html t
            mu4e-update-interval 180
            mu4e-headers-auto-update t
            mu4e-compose-signature-auto-include nil
            mu4e-compose-format-flowed t)

      ;; to view selected message in the browser, no signin, just html mail
      (add-to-list 'mu4e-view-actions
                   '("ViewInBrowser" . mu4e-action-view-in-browser) t)

      ;; enable inline images
      (setq mu4e-view-show-images t)
      ;; use imagemagick, if available
      (when (fboundp 'imagemagick-register-types)
        (imagemagick-register-types))

      ;; every new email composition gets its own frame!
      ;(setq mu4e-compose-in-new-frame t)
      ;; trying with each in new window
      (setq mu4e-compose-in-new-window t)
      ;; don't save message to Sent Messages, IMAP takes care of this
      (setq mu4e-sent-messages-behavior 'delete)

      (add-hook 'mu4e-view-mode-hook #'visual-line-mode)

      ;; <tab> to navigate to links, <RET> to open them in browser
      (add-hook 'mu4e-view-mode-hook
                (lambda()
                  ;; try to emulate some of the eww key-bindings
                  (local-set-key (kbd "<RET>") 'mu4e~view-browse-url-from-binding)
                  (local-set-key (kbd "<tab>") 'shr-next-link)
                  (local-set-key (kbd "<backtab>") 'shr-previous-link)))

      ;; from https://www.reddit.com/r/emacs/comments/bfsck6/mu4e_for_dummies/elgoumx
      (add-hook 'mu4e-headers-mode-hook
                (defun my/mu4e-change-headers ()
                  (interactive)
                  (setq mu4e-headers-fields
                        `((:human-date . 25) ;; alternatively, use :date

                          (:flags . 6)
                          (:from . 22)
                          (:thread-subject . ,(- (window-body-width) 70)) ;; alternatively, use :subject
                          (:size . 7)))))

      ;; if you use date instead of human-date in the above, use this setting
      ;; give me ISO(ish) format date-time stamps in the header list
                                            ;(setq mu4e-headers-date-format "%Y-%m-%d %H:%M")

      ;; spell check
      (add-hook 'mu4e-compose-mode-hook
                (defun my-do-compose-stuff ()
                  "My settings for message composition."
                  (visual-line-mode)
                  (org-mu4e-compose-org-mode)
                  (use-hard-newlines -1)
                  (flyspell-mode)))

      (require 'smtpmail)

      ;;rename files when moving
      ;;NEEDED FOR MBSYNC
      (setq mu4e-change-filenames-when-moving t)

      ;;set up queue for offline email
      ;;use mu mkdir  ~/Maildir/acc/queue to set up first
      (setq smtpmail-queue-mail nil)  ;; start in normal mode

      ;;from the info manual
      (setq mu4e-attachment-dir  "~/Downloads")

      (setq message-kill-buffer-on-exit t)
      (setq mu4e-compose-dont-reply-to-self t)


      ;; convert org mode to HTML automatically
      ;(setq org-mu4e-convert-to-html t)
      ;(require 'org-mu4e)
      (use-package org-mu4e
        :ensure nil
        :custom
        (org-mu4e-convert-to-html t))

         ;;from vxlabs config
      ;; show full addresses in view message (instead of just names)
      ;; toggle per name with M-RET
      (setq mu4e-view-show-addresses 't)

      ;; don't ask when quitting
      (setq mu4e-confirm-quit nil)

      ;; mu4e-context
      (setq mu4e-context-policy 'pick-first)
      (setq mu4e-compose-context-policy 'always-ask)
      (setq mu4e-contexts
            (list
               ;; The line below is a target to append future contexts to the file
         ;;CONTEXTINSERTIONSITE

  )))



#+END_SRC


** add attachments from dired
#+BEGIN_SRC emacs-lisp
(require 'gnus-dired)
;; make the `gnus-dired-mail-buffers' function also work on
;; message-mode derived modes, such as mu4e-compose-mode
(defun gnus-dired-mail-buffers ()
  "Return a list of active message buffers."
  (let (buffers)
    (save-current-buffer
      (dolist (buffer (buffer-list t))
	(set-buffer buffer)
	(when (and (derived-mode-p 'message-mode)
		(null message-sent-message-via))
	  (push (buffer-name buffer) buffers))))
    (nreverse buffers)))

(setq gnus-dired-mail-mode 'mu4e-user-agent)
(add-hook 'dired-mode-hook 'turn-on-gnus-dired-mode)

#+END_SRC
EOF
}


function template_make_lisp_context {
    # Template for mu4e's lisp configuration in LISPCONFIGFILE ("email.org")
    # First added to a temporary file ACCOUNTPROVIDER-context,
    # Then inserted into LISPCONFIGFILE at specified site
    local MU4ENAME USERFULLNAME
    
    echo -e "Enter a context name for ${ACCOUNTPROVIDER} within mu4e's menus\n "
    read -p "Warning: use different first letters for all account's context names: " MU4ENAME 
    read -p "Enter the name you want to address these emails from {ex. Jane Doe}: " USERFULLNAME
    
    cat<<EOF> "${ACCOUNTPROVIDER}-context"
        (make-mu4e-context ;; $EMAILADDRESS
            :name "$MU4ENAME" ;;for $ACCOUNTPROVIDER
            :enter-func (lambda () (mu4e-message "Entering context work"))
            :leave-func (lambda () (mu4e-message "Leaving context work"))
            :match-func (lambda (msg)
                          (when msg
                        (mu4e-message-contact-field-matches
                         msg '(:from :to :cc :bcc) "$EMAILADDRESS")))
            :vars '((user-mail-address . "$EMAILADDRESS")
                    (user-full-name . "$USERFULLNAME")
                    (mu4e-sent-folder . "/$ACCOUNTPROVIDER/Sent Mail")
                    (mu4e-drafts-folder . "/$ACCOUNTPROVIDER/drafts")
                    (mu4e-trash-folder . "/$ACCOUNTPROVIDER/Bin")
                    (mu4e-compose-signature . (concat "Formal Signature\n" "Emacs , org-mode , mu4e \n"))
                    (mu4e-compose-format-flowed . t)
                    (smtpmail-queue-dir . "~/Maildir/$ACCOUNTPROVIDER/queue/cur")
                    (message-send-mail-function . smtpmail-send-it)
                    (smtpmail-smtp-user . "$ACCOUNT")
                    (smtpmail-starttls-credentials . (("smtp.$PROVIDER.com" 587 nil nil)))
                    (smtpmail-auth-credentials . (expand-file-name "~/.authinfo.gpg"))
                    (smtpmail-default-smtp-server . "smtp.$PROVIDER.com")
                    (smtpmail-smtp-server . "smtp.$PROVIDER.com")
                    (smtpmail-smtp-service . 587)
                    (smtpmail-debug-info . t)
                    (smtpmail-debug-verbose . t)
                    (mu4e-maildir-shortcuts . ( ("/$ACCOUNTPROVIDER/INBOX"                . ?i)
                                                ("/$ACCOUNTPROVIDER/Sent Mail" . ?s)
                                                ("/$ACCOUNTPROVIDER/Bin"       . ?t)
                                                ("/$ACCOUNTPROVIDER/All Mail"  . ?a)
                                                ("/$ACCOUNTPROVIDER/drafts"    . ?d)
                                                ))))
         ;; The line below is a target to append future contexts to the file
         ;;CONTEXTINSERTIONSITE
EOF
    echo -e "\n"
    
    # Create email config from template if it doesn't exist
    # insert account's information into email config
    # symlink email config file from mu4e to .emacs.d, for use by init.el or config.org
    if [[ ! -f ${LISPCONFIGFILE} ]]; then template_main_email_config; fi
    sed -i "/;;CONTEXTINSERTIONSITE/r./${ACCOUNTPROVIDER}-context" "${LISPCONFIGFILE}"
    rm "${ACCOUNTPROVIDER}-context"
    ln -s "$HOME/.emacs.d/mu4e/${LISPCONFIGFILE}" "$HOME/.emacs.d/"
}

