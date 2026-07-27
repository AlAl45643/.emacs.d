;;; rules
;;;; package rules
;;;;; guiding values
;; 1. Modularity decreases development costs by limiting complexity.
;;;;; feature rules
;; + Every section except core should be modular.
;; + use package last parantheses should not be on its own line
;; + don't use custom but setopt instead since it messes with completion
;; + put setopts in :init as customization avoids loading as much as it can
;; + diminish should be on the last line
;; + :demand :mode :hook :general  :init :config :general-config
;; + prefer loading packages with of :hooks and :general instead of :after :init :config but with 
;; + one line for each :hook
;; + hooks should be placed in the package where the function was provided
;;;; keybind rules
;;;;; guiding values
;; + A keybind should be 1. useful 2. memorable 3. shorter than less used and longer than more used keybinds 4. easy to press
;; + Structure makes memorable keybinds.
;; + Keybinds can be separated into three semantic categories. The first being keybinds that are only useful within a context (mode), the second being keybinds that are useful in any context (mode), and the third being keybinds that are somewhere between. 
;; + Emacs prefixes should be incorporated into your keybind scheme so that you can discover more useful keybinds and that your keybind scheme if not optimal is most likely useful.
;;;;; binding rules
;; 1. Is the command always useful? If it is then bind it globally. If not, which mode and state is it useful in?
;; 2. What is the shortest memorable keybind you can think of?
;; 3. Is the keybind available? if it is, then bind the keybind to the command. If not, then is the command currently bound less used than our command? if it is, then replace the command and if command used redo step 7 for the command you replaced. if it is not, then think of the next shortest memorable keybind and redo step 3.

;; + SPC prefix commands should be commands with higher frequency of use than , prefix commands.
;; + The \ prefix and the SPC prefix are restricted to global commands while the , prefix is restricted to major mode.
;; + Inbetween keybinds shall be global through functions or local depending on whichever solution is cleaner.
;; + Incorporate emacs prefixes such as C-h and C-x.
;; + Prefer binding to prefix-maps when incorporating emacs prefixes.
;; + Only defer load for keybinds when keymap isn't available or commands aren't needed until package is loaded.
;; + Keybinds should be put in the package definition that provides them
;; + Use M-F instead of M-S-f

;;;;; keybind conventions
;; q ephermal quit
;; Z Q non epehermal quit
;; C-j C-k for history elements
;; g j g k next same heading
;; ]] [[ next visible heading
;; C-S-j C-S-k next grouping or scroll
;; should M or S or C have meanings?
;;; core
(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

(setq elpaca-lock-file (concat user-emacs-directory "lock-file"))

(defun fuzzbomb-startup--emacs-uptime-micro ()
  "Return the uptime in seconds and microseconds."
  (format-time-string "%-S.%3N seconds" (time-since before-init-time)))

(add-hook 'window-setup-hook
          (lambda ()
            (message "End window-setup-hook: %s"
                     (fuzzbomb-startup--emacs-uptime-micro)))
                                        ; This goes against the general advice to avoid depth values of 100.
                                        ; But here, doing it last is the whole point!
          100)


(use-package el-patch
  :ensure (:wait t))


(use-package use-package-core
  :custom
  (use-package-always-defer t))

(use-package general
  :ensure (:wait t)
  :config
  (general-evil-setup)
  (general-auto-unbind-keys)
  )


;;;; my-main-leader-evil-map
(defun my-run-program ()
  "Run program at point depending on mode."
  (interactive)
  (cond
   ((or (equal major-mode 'python-ts-mode) (equal major-mode 'python-mode))
    (when (get-buffer "*Python*")
      (let ((kill-buffer-query-functions nil))
        (kill-buffer "*Python*")
        ))
    (save-excursion (run-python "python3 -i" 'project t))
    (sit-for 1)
    (python-shell-send-buffer)
    (pop-to-buffer (python-shell-get-buffer)))
   ((or (equal major-mode 'csharp-mode) (equal major-mode 'csharp-ts-mode)) (sharper-transient-run))
   ((equal major-mode 'LaTeX-mode) (call-interactively #'TeX-command-master))
   ((equal major-mode 'sql-mode) (call-interactively #'sql-send-buffer))
   (t (message "No program to run"))))

(defun my-eval-expression ()
  "Eval expression depending on mode."
  (interactive)
  (cond
   ((and (featurep 'dape) dape-active-mode)
    (call-interactively #'dape-evaluate-expression))
   ((and (featurep 'edebug) edebug-mode)
    (call-interactively #'edebug-eval-expression))
   ((and (featurep 'slime-py) (or (equal major-mode 'python-mode) (equal major-mode 'python-ts-mode)))
    (call-interactively #'slime-interactive-eval))
   (t (call-interactively #'eval-expression)))
  )

(defun my-eval-defun ()
  "Eval defun depending on mode."
  (interactive)
  (cond
   ((and (featurep 'slime-py) (or (equal major-mode 'python-mode) (equal major-mode 'python-ts-mode)))
    (call-interactively #'slime-eval-defun))
   (t (call-interactively #'eval-defun))))


(defun my-window-bookmark-home ()
  "Move to home bookmark."
  (interactive)
  (bookmark-maybe-load-default-file)
  ;; work around to get org-agenda buffer working in bookmarks
  (org-agenda-list)
  (bookmark-jump "Burly: home")
  (with-selected-window (get-buffer-window "*Org Agenda*")
    (org-agenda-goto-today)
    (call-interactively #'evil-scroll-line-to-top)))


(defun my-window-bookmark-init ()
  "Move to init bookmark."
  (interactive)
  (bookmark-maybe-load-default-file)
  (bookmark-jump "Burly: init"))


(general-define-key
 :keymaps 'override
 :states '(insert normal hybrid motion visual operator)
 :prefix-map 'my-main-leader-map
 :prefix "SPC"
 :non-normal-prefix "C-SPC")

(general-create-definer main-leader-definer
  :keymaps 'my-main-leader-map)

(main-leader-definer
  "s" 'switch-to-buffer
  "e" 'popper-cycle
  "r" 'my-run-program
  "t" 'popper-toggle
  "p" 'org-pomodoro
  "f" 'find-file
  "l" 'eshell
  "d" 'dired-jump
  "n" 'my-eval-defun
  "i" 'consult-imenu
  "g" 'magit-project-status
  "k" 'kill-buffer
  "v" 'my-eval-expression
  "a" 'org-agenda-list
  "c" 'visual-line-mode
  "m" 'make-frame-command
  "1" 'my-window-bookmark-home
  "2" 'my-window-bookmark-init
  "o" 'consult-outline
  "y" 'evil-avy-goto-char
  "=" 'text-scale-adjust
  "-" 'text-scale-adjust
  "0" '("text-scale-adjust-0" . (lambda () (interactive) (text-scale-decrease 0)))
  "b" 'ibuffer
  "&" 'async-shell-command
  "!" 'compile
  "w" 'window-toggle-side-windows
  )

;;;; my-second-leader-evil-map

(defun my-test-code ()
  "Run test cases for program."
  (interactive)
  (cond
   ((or (equal major-mode 'csharp-mode) (equal major-mode 'csharp-ts-mode))
    (sharper-transient-test))
   (t (message "%s" "No test cases to run."))))

(defun my-build-code ()
  "Build program."
  (interactive)
  (cond
   ((or (equal major-mode 'csharp-mode) (equal major-mode 'csharp-ts-mode))
    (sharper-transient-build))
   (t (message "%s" "No program to build."))))

(defun my-code-action ()
  "Perform code actions at point."
  (interactive)
  (cond
   ((and (featurep 'eglot) eglot--managed-mode) (call-interactively 'eglot-code-actions))
   (t (message "%s" "No code actions at point."))))




(defun my-code-rename ()
  (interactive)
  (cond
   ((and (featurep 'eglot) eglot--managed-mode) (call-interactively 'eglot-rename))
   (t (message "%s" "Nothing to rename at point."))))

(defun my-eval-last-sexp ()
  (interactive)
  (cond
   ((and (featurep 'slime-py) (or (equal major-mode 'python-ts-mode) (equal major-mode 'python-mode)))
    (call-interactively #'slime-py-eval-statement-at-point))
   ((and (featurep 'edebug) edebug-mode)
    (call-interactively #'edebug-eval-last-sexp))
   (t (call-interactively #'eval-last-sexp))))

(defun my-eval-region ()
  (interactive)
  (cond
   ((and (featurep 'slime-py) (or (equal major-mode 'python-ts-mode) (equal major-mode 'python-mode)))
    (call-interactively #'slime-eval-region))
   (t (call-interactively #'eval-region))))

(defun my-eval-buffer ()
  (interactive)
  (cond
   ((and (featurep 'slime-py) (or (equal major-mode 'python-ts-mode) (equal major-mode 'python-mode)))
    (call-interactively #'slime-eval-buffer))
   (t (call-interactively #'eval-buffer))))

(defun narrow-to-page-indirect ()
  (interactive)
  (let ((buf (clone-indirect-buffer nil nil)))
    (with-current-buffer buf
      (narrow-to-page))
      (switch-to-buffer buf)))

(defun narrow-to-defun-indirect ()
  (interactive)
  (let ((buf (clone-indirect-buffer nil nil)))
    (with-current-buffer buf
      (narrow-to-defun)
      (switch-to-buffer buf))))

(defun narrow-to-region-indirect (start end)
  "Restrict editing in this buffer to the current region, indirectly."
  (interactive "r")
  (deactivate-mark)
  (let ((buf (clone-indirect-buffer nil nil)))
    (with-current-buffer buf
      (narrow-to-region start end))
      (switch-to-buffer buf)))


(general-define-key
 :keymaps 'override
 :states '(insert normal hybrid motion visual operator)
 :prefix-map 'my-second-leader-map
 :prefix "\\"
 :non-normal-prefix "C-\\")

(defmacro +general-global-menu! (name prefix-key &rest body)
  "Create a definer named +general-global-NAME.
  Create prefix map: +general-global-NAME. Prefix bindings in BODY with INFIX-KEY."
  (declare (indent 2))
  `(progn
     ;; find a way to replace this with keymap based replacement
     (which-key-add-key-based-replacements (concat "\\ " ,prefix-key) ,name)
     (which-key-add-key-based-replacements (concat "C-\\ " ,prefix-key) ,name)
     (general-define-key
      :keymaps 'my-second-leader-map
      :prefix-map ',(intern (concat "my-" name "-map"))
      :prefix ,prefix-key)
     (general-create-definer ,(intern (concat "+general-global-" name))
       :keymaps ',(intern (concat "my-" name "-map")))
     (,(intern (concat "+general-global-" name))
      ,@body)))

(+general-global-menu! "code" "e"
  "t" 'my-test-code
  "b" 'my-build-code
  "a" 'my-code-action
  "d" 'dape
  "n" 'my-code-rename
  "k" 'docker
  "e" 'eglot
  )

(+general-global-menu! "consult" "c"
  "g" 'consult-grep
  "f" 'consult-find
  "o" 'consult-outline)

(+general-global-menu! "miscellaneous" "s"
  "c" 'calc
  )

(+general-global-menu! "elpaca" "l"
  "v" 'elpaca-visit
  "l" 'elpaca-log
  "m" 'elpaca-manager
  "t" 'elpaca-try)

(+general-global-menu! "eval" "v"
  "s" 'my-eval-last-sexp
  "b" 'my-eval-buffer
  "r" 'my-eval-region)

(+general-global-menu! "completion" "p"
  "p" 'completion-at-point)

(+general-global-menu! "git" "g"
  "x" 'diff-hl-revert-hunk
  "d" 'diff-hl-diff-goto-hunk
  "s" 'diff-hl-stage-dwim)

(+general-global-menu! "project" "j"
  "f" 'project-find-file
  "s" 'project-switch-to-buffer
  "j" 'project-switch-project
  "h" 'project-search)

(+general-global-menu! "file" "f"
  "d" 'delete-file
  "c" 'copy-file)

(+general-global-menu! "window" "w"
  "h" 'windmove-display-left
  "l" 'windmove-display-right
  "j" 'windmove-display-down
  "k" 'windmove-display-up)

(+general-global-menu! "narrow" "n"
  "p" 'narrow-to-page-indirect
  "d" 'narrow-to-defun-indirect
  "r" 'narrow-to-region-indirect
  "w" 'kill-current-buffer)


;;;; simulation keys
(general-def '(normal visual) 'override
  "," (general-simulate-key "C-c")
  "<menu>" (general-simulate-key "C-c")
  "C-c ," 'evil-repeat-find-char-reverse)
(general-def 'insert 'override
  "C-," (general-simulate-key "C-c")
  "C-<menu>" (general-simulate-key "C-c"))
;;; evil suite
(defun smart-tab ()
  (interactive)
  (cond ((buffer-local-value 'vertico--input (current-buffer)) (vertico-insert))
        ;; Slime Eval returns weird errors if we use completion so use hippie-expand only
        ((and (minibufferp) (equal (minibuffer-prompt) "Slime Eval: "))
         (hippie-expand nil))
        ;; necessary because we use vertico in the minibuffer and eshell which requires tab to start completion menu
        ((or (minibufferp) (derived-mode-p 'eshell-mode))
         (let ((res (run-hook-wrapped 'completion-at-point-functions #'completion--capf-wrapper 'all)))
           (if res
               (completion-at-point)
             (hippie-expand nil)))) 
        ;; if corfu frame is visible use corfu else hippie-expand for quick completion
        ((and (frame-live-p corfu--frame) (frame-visible-p corfu--frame)) (corfu-insert))
        ((looking-at "\\_>") (hippie-expand nil))
        (t (indent-for-tab-command))))

(defun my-format-buffer ()
  (interactive)
  (cond
   ((and (featurep 'eglot) eglot--managed-mode (eglot-server-capable :documentFormattingProvider))
    (call-interactively #'eglot-format-buffer))
   (t (indent-region (point-min) (point-max)))))

(defun my-delete-back-to-char ()
  "Delete backward to char."
  (interactive)
  (while (or (equal (preceding-char) ?\n) (equal (preceding-char) ?\s) (equal (preceding-char) ?\t))
    (backward-delete-char-untabify 1)))

(use-package evil 
  :ensure t
  :demand t
  :init
  (setopt
   evil-undo-system 'undo-redo
   evil-want-keybinding nil
   evil-want-minibuffer t
   evil-emacs-state-modes nil
   evil-insert-state-modes nil
   evil-motion-state-modes nil
   evil-insert-state-message nil
   evil-emacs-state-message nil
   evil-replace-state-message nil
   evil-visual-state-message nil
   evil-mode-line-format nil
   evil-visual-char-message nil
   evil-visual-line-message nil
   evil-visual-block-message nil
   evil-respect-visual-line-mode t
   evil-visual-screen-line-message nil
   evil-move-beyond-eol t)
  (evil-mode 1)
  :config
  (evil-define-command my-evil-window-vsplit-left (&optional count file)
    "Split the current window vertically, COUNT columns width,
editing a certain FILE. The new window will be created to the
left. If COUNT and `evil-auto-balance-windows'are both non-nil
then all children of the parent of the splitted window are
rebalanced."
    :repeat nil
    (interactive "<wc><f>")
    (split-window (selected-window) (when count (- count))
                  'left)
    (when (and (not count) evil-auto-balance-windows)
      (balance-windows (window-parent)))
    (when file
      (evil-edit file)))
  (evil-define-motion my-evil-end-of-visual-line (count)
    "Move the cursor to the last character of the current screen line.
If COUNT is given, move COUNT - 1 screen lines downward first."
    :type inclusive
    (end-of-visual-line count)
    (unless evil-move-beyond-eol
      (evil-move-cursor-back t)))
  (advice-add 'evil-end-of-visual-line :override #'my-evil-end-of-visual-line)
  :general-config
  ('normal
   "=" (general-key-dispatch 'evil-indent
         "=" 'my-format-buffer)
   "C-S-d" 'evil-scroll-up
   "[ x" 'xref-go-back
   "] x" 'xref-go-forward
   "g d" 'xref-find-definitions
   "g D" 'xref-find-definitions-other-window
   "C-w C-v" 'my-evil-window-vsplit-left
   )
  ('insert
   "TAB" 'smart-tab
   "C-b" 'my-delete-back-to-char)
  ('insert prog-mode-map
           "S-<return>" 'evil-open-below)
  ('(normal insert)                     
   "C-S-f" 'scroll-other-window         
   "C-S-b" 'scroll-other-window-down
   )
  )

(use-package paredit
  :ensure t
  :init
  (require 'paredit)
  :general-config
  ('(normal insert)                     
   "M-j" 'paredit-forward
   "M-k" 'paredit-backward
   "M-h" 'paredit-backward-up
   "M-H" 'paredit-backward-down
   "M-l" 'paredit-forward-down
   "M-L" 'paredit-forward-up
   "M-a" 'beginning-of-defun
   "M-e" 'end-of-defun
   "M-r" 'paredit-raise-sexp
   ))

(defun my-combobulate-keybinds ()
  (general-def '(normal insert visual) '(combobulate-css-map combobulate-html-map combobulate-javascript-map combobulate-typescript-map combobulate-python-map)
    "M-j" 'combobulate-navigate-next
    "M-k" 'combobulate-navigate-previous
    "M-h" 'combobulate-navigate-up
    "M-l" 'combobulate-navigate-down
    "M-a" 'combobulate-navigate-beginning-of-defun
    "M-e" 'combobulate-navigate-end-of-defun
    "M-r" 'combobulate-splice-up
    ;; "M-X" 'combobulate-kill-node-dwim
    ;; "<deletechar>" 'combobulate-kill-node-dwim
  )
  (evil-normalize-keymaps))

(use-package combobulate
  :ensure (:host github :repo "mickeynp/combobulate")
  :hook
  ((python-ts-mode astro-ts-mode jtsx-jsx-mode jtsx-tsx-mode jtsx-typescript-mode
                   js-mode js-ts-mode typescript-ts-mode tsx-ts-mode css-mode css-ts-mode svelte-mode svelte-ts-mode vue-mode vue-ts-mode) . combobulate-mode)
  ((combobulate-python-minor-mode combobulate-css-minor-mode combobulate-html-minor-mode combobulate-javascript-minor-mode combobulate-typescript-minor-mode) . #'my-combobulate-keybinds)
  :init
  (setopt
   combobulate-flash-node nil)
  )


(use-package avy
  :ensure t
  :init
  (setopt
   avy-all-windows nil
   avy-all-windows-alt t
   avy-case-fold-search nil))




(use-package evil-collection
  :ensure t
  :hook (evil-mode . evil-collection-init)
  :init
  (setopt
   evil-collection-elpaca-want-v nil
   evil-collection-elpaca-want-movement nil
   evil-collection-repl-submit-state 'insert
   evil-collection-setup-minibuffer t
   evil-collection-outline-bind-tab-p t
   evil-collection-key-blacklist '("M-h" "M-j" "M-k" "M-l")
   evil-collection-mode-list '(2048-game ag python agent-shell alchemist anaconda-mode apropos arc-mode
                                         atomic-chrome auto-package-update beginend bluetooth bm
                                         bookmark (buff-menu "buff-menu") bufler calc calendar cider
                                         citre cmake-mode color-rg comint company compile consult
                                         corfu crdt (csv "csv-mode") (custom cus-edit) cus-theme
                                         dape dashboard daemons deadgrep debbugs debug devdocs
                                         dictionary diff-hl diff-mode difftastic dired dired-sidebar
                                         disk-usage distel doc-view docker eat ebib ebuku eca edbi
                                         edebug ediff eglot elpaca ement explain-pause-mode eldoc
                                         elfeed elisp-mode elisp-refs elisp-slime-nav embark emms
                                         emoji epa ert eshell eval-sexp-fu evil-mc eww fanyi finder
                                         flycheck flymake fj forge free-keys fzfa geiser ggtags
                                         git-timemachine gited gnus go-mode gptel grep guix
                                         hackernews helm help helpful hg-histedit hideshow
                                         hungry-delete hyrolo ibuffer ielm (image image-mode)
                                         image-dired image+ imenu imenu-list (indent "indent")
                                         indium info ivy js2-mode kmacro leetcode lispy lms log-edit
                                         log-view lsp-ui-imenu lua-mode kotlin-mode macrostep man
                                         (magit magit-submodule) magit-repos magit-section
                                         magit-todos markdown-mode message minesweeper minibuffer
                                         monky mpc mpdel mpdired mu4e mu4e-conversation neotree
                                         newsticker notmuch nov omnisharp org org-agenda org-present
                                         org-roam osx-dictionary outline ovpn-mode p4
                                         (package-menu package) pass (pdf pdf-view) popup proced
                                         (process-menu simple) prodigy profiler p-search
                                         quickrun racer racket-describe reader realgud reftex
                                         replace restclient rg ripgrep rjsx-mode robe rtags
                                         ruby-mode scheme scroll-lock selectrum sh-script
                                         shell-maker shortdoc simple simple-mpc slime sly
                                         smerge-mode snake so-long speedbar tab-bar tablist
                                         tabulated-list tar-mode telega
                                         (term term ansi-term multi-term) tetris thread tide
                                         timer-list transmission trashed tuareg typescript-mode
                                         ultra-scroll vc-annotate vc-dir vc-git vdiff vertico view
                                         vlf vterm vundo w3m wdired wgrep which-key with-editor
                                         woman xref xwidget yaml-mode youtube-dl zmusic
                                         (ztree ztree-diff ztree-dir))))



(use-package evim
  :ensure t
  :hook (evil-mode . evim-setup-global-keys)
  :config
  (setopt
   evim-leader-key "g .")
  (which-key-add-key-based-replacements "\\ ." "evim")
  (defun evim-esc ()
    "Toggle from extend->cursor->normal"
    (interactive)
    (when (evim-active-p)
      (if (evim-cursor-mode-p)
          (evim-exit)
        (evim--enter-cursor-mode))))
  (if (eq warning-suppress-log-types nil)
      (setopt warning-suppress-log-types '((org-element org-element-cache)))
    (add-to-list warning-suppress-log-types '(org-element org-element-cache)))
  :general-config
  (evim-mode-map
   "<escape>" 'evim-esc)
  )

(use-package evil-owl
  :ensure t
  :hook (evil-mode . evil-owl-mode)
  :init
  (setopt
   evil-owl-display-method 'posframe
   evil-owl-max-string-length 50
   evil-owl-idle-delay 0.5)
  :custom
  (evil-owl-extra-posframe-args '(:width 50 :height 20)))

(use-package evil-commentary
  :ensure t
  :hook (prog-mode . evil-commentary-mode))


(use-package evil-surround
  :ensure t
  :hook (evil-mode . global-evil-surround-mode))
(use-package posframe
  :ensure t)
;;; org

;;;; org tasks and notes
(defun my-org-agenda-to-appt ()
  "Erase all reminders and rebuilt reminders for today from the agenda."
  (interactive)
  (setq appt-time-msg-list nil)
  (org-agenda-to-appt))

(defun org-match-sparse-tree-heading ()
  "Check heading of each tag."
  (interactive)
  (org-save-outline-visibility nil
    (org-match-sparse-tree)
    ))

(defvar my-annoying-timer (list))


(defun my-create-annoying-sound ()
  "Play an annoying sound if org-pomdoro is not started, else cancel `my-annoying-timer'."
  (require 'org-pomodoro)
  (if (and (eq org-pomodoro-state :none) (not (org-clocking-p)))
      (start-process "play-sound" nil "aplay" (concat (expand-file-name user-emacs-directory) "bell.wav"))
    (cancel-timer (pop my-annoying-timer))))


(defun my-create-annoying-timer (time)
  "Create an annoying timer that repeats until pomodoro is started."
  (require 'diary-lib)
  (let ((hhmm (diary-entry-time time))
        (now (decode-time)))
    (when (>= hhmm 0)
      (setq time (encode-time 0 (% hhmm 100) (/ hhmm 100)
                              (decoded-time-day now)
                              (decoded-time-month now)
                              (decoded-time-year now)
                              (decoded-time-zone now)))
      )
    (unless (time-less-p time (current-time))
      (let ((timer (run-at-time time 1 #'my-create-annoying-sound)))
        (push timer my-annoying-timer)))))



(defun my-org-shift-match-timestamps (match hour min)
  "Shift timestamps that match `match' time by `hour' hours and `min' minutes."
  (interactive "sMatch: \nnHours: \nnMins: ")
  (with-current-buffer "TODO.org"
    (goto-char 0)
    (while-let
        ((timestamp-pos (ignore-errors (re-search-forward (org-re-timestamp 'active))))
         (timestamp (match-string 0))
         (time (org-time-string-to-time timestamp))
         (match-time (parse-time-string match 1))
         (time-hour (string-to-number (format-time-string "%H" time)))
         (time-min (string-to-number (format-time-string "%M" time)))
         (match-time-hour (decoded-time-hour match-time))
         (match-time-min (decoded-time-minute match-time)))
      (when (and (eql match-time-min time-min)
                 (eql match-time-hour time-hour))
        (org-timestamp-change hour 'hour)
        (org-timestamp-change min 'minute))
      )))

(defun my-org-shift-scheduled-timestamps (hour min)
  "Shift scheduled timestamps by `hour' hours and `min' minutes."
  (interactive "nHour: \nnMins: ")
  (with-current-buffer "TODO.org"
    (goto-char 0)
    (while-let
        ((timestamp-pos (ignore-errors (re-search-forward (org-re-timestamp 'scheduled))))
         (timestamp (match-string 0))
         (time (org-time-string-to-time timestamp)))
      (org-timestamp-change hour 'hour)
      (org-timestamp-change min 'minute)
      )))

(use-package org
  :ensure t
  :mode ("\\.org\\'" . org-mode)
  :hook
  (org-agenda-finalize . my-org-agenda-to-appt)
  (org-metaleft-final . (lambda () (interactive) (call-interactively #'backward-up-list) t))
  (org-metaright-final . (lambda () (interactive) (call-interactively #'down-list) t))
  (org-metaup-final . (lambda () (interactive) (call-interactively #'backward-list) t))
  (org-metadown-final . (lambda () (interactive) (call-interactively #'forward-list) t))
  (org-shiftmetaup-final . (lambda () (interactive) (call-interactively #'backward-sexp) t))
  (org-shiftmetadown-final . (lambda () (interactive) (call-interactively #'forward-sexp) t))
  (org-shiftmetaleft-final . (lambda () (interactive) (call-interactively #'up-list) t))
  :general-config
  (org-mode-map
   "C-<tab>" 'org-cycle
   "C-<iso-lefttab>" 'org-shifttab
   "C-c t" 'org-match-sparse-tree-heading)
  :init
  (require 'org-habit)
  (add-to-list 'org-modules 'org-habit t)
  (custom-set-faces
   '(org-habit-alert-face
     ((t (:background "#2dc937"
                      :foreground "black"))))
   '(org-habit-alert-future-face
     ((t (:background "#2dc937"
                      :foreground "black"))))
   '(org-habit-clear-future-face
     ((t (:background "#e7b416"
                      :foreground "black"))))
   '(org-habit-clear-face
     ((t (:background "#e7b416"
                      :foreground "black"))))
   '(org-habit-overdue-face
     ((t (:background "#cc3232"
                      :foreground "black"))))
   '(org-habit-overdue-future-face
     ((t (:background "#cc3232"
                      :foreground "black"))))
   '(org-habit-ready-face
     ((t (:background "#2dc937"
                      :foreground "black"))))
   '(org-habit-ready-future-face
     ((t (:background "#2dc937"
                      :foreground "black")))))
  (setopt
   org-startup-folded 'fold
   org-habit-graph-column 50
   org-habit-show-habits-only-for-today nil
   org-habit-preceding-days 15
   org-habit-following-days 14
   org-clock-sound (concat user-emacs-directory "finished.wav")
   org-agenda-timegrid-use-ampm t
   appt-activate t
   org-log-done 'time
   org-agenda-files nil
   org-habit-overdue-glyph ?○
   org-habit-alert-glyph ?○
   org-habit-ready-future-glyph ?○
   org-habit-today-glyph ?○
   org-habit-completed-glyph ?●
   org-log-into-drawer t
   org-agenda-files '("~/org/TODO.org")
   org-preview-latex-process-alist '((dvipng :programs ("docker")  :description "dvi > png"
                                             :message
                                             "you need to install the programs: docker."
                                             :image-input-type "dvi" :image-output-type "png"
                                             :image-size-adjust (2.0 . 2.0) :latex-compiler
                                             ("docker cp %f latex:/workdir/%b.tex && docker exec latex latex -interaction nonstopmode /workdir/%b.tex && docker cp latex:/workdir/%b.dvi /tmp/%b.dvi")
                                             :image-converter ("docker exec latex dvipng -D %D -T tight /workdir/%b.dvi && docker cp latex:/workdir/%b1.png %O")
                                             :transparent-image-converter
                                             ("docker exec latex dvipng -D %D -T tight -bg Transparent /workdir/%b.dvi && docker cp latex:/workdir/%b1.png %O"
                                              )))
   org-latex-packages-alist '(("" "cancel" t ("pdflatex")))
   org-imenu-depth 1)
  :config
  (org-babel-do-load-languages 'org-babel-load-languages '((plantuml . t)
                                                           (dot . t)
                                                           (python . t)
                                                           (js . t)
                                                           (racket . t)
                                                           (html . t)))
  (run-at-time "24:01" nil 'my-org-agenda-to-appt)
  (modify-syntax-entry ?< "." org-mode-syntax-table)
  (modify-syntax-entry ?> "." org-mode-syntax-table))


(defun my-org-pomodoro-choose-break-time (arg)
  "Choose break time for pomodoro."
  (interactive "nBreak time (0 if overtime): ")
  (setq org-pomodoro-short-break-length arg))

(defun my-org-pomodoro-finished-with-overtime-advice (orig-fun &rest args)
  "Advise around `org-pomodoro-finished' to choose break time"
  (org-pomodoro-play-sound :pomodoro)
  (call-interactively #'my-org-pomodoro-choose-break-time)
  (cond ((= org-pomodoro-short-break-length 0) (org-pomodoro-overtime))
        ((zerop (mod (+ org-pomodoro-count 1) org-pomodoro-long-break-frequency)) (apply orig-fun args))
        (t (apply orig-fun args))))


(defun my-org-pomodoro-resume-after-break ()
  "Resume pomodoro timer if pomodoro timer is not currently in overtime."
  (save-window-excursion
    (org-clock-goto)
    (org-pomodoro)))

(defun my-org-pomodoro-clockout-before-kill-advice ()
  "Clock out time before exiting `org-pomodoro' so time is accurately tracked."
  (if (org-clocking-p)
      (save-window-excursion
        (org-clock-out))))

(defvar my-killed-pomodoro-time 30 "Value when pomdoro is killed.")


(use-package org-pomodoro
  :ensure t
  :hook (org-pomodoro-break-finished . my-org-pomodoro-resume-after-break)
  :init
  (setopt
   org-pomodoro-ask-upon-killing t
   org-pomodoro-finished-sound (concat user-emacs-directory "finished.wav")
   ;; 30 15 11 7
   ;; 15 8 6 4
   org-pomodoro-length 15 
   org-pomodoro-short-break-length 4
   org-pomodoro-long-break-length 8
   org-pomodoro-start-sound (concat user-emacs-directory "bell.wav")
   org-pomodoro-start-sound-p t)
  :config
  (el-patch-defun org-pomodoro (&optional arg)
    "Start a new pomodoro or stop the current one.

When no timer is running for `org-pomodoro` a new pomodoro is started and
the current task is clocked in.  Otherwise EMACS will ask whether we´d like to
kill the current timer, this may be a break or a running pomodoro."
    (interactive "P")

    (when (and org-pomodoro-last-clock-in
               org-pomodoro-expiry-time
               (org-pomodoro-expires-p)
               (y-or-n-p "Reset pomodoro count? "))
      (setq org-pomodoro-count 0))
    (setq org-pomodoro-last-clock-in (current-time))

    (cond
     ;; possibly break from overtime
     ((and (org-pomodoro-active-p) (eq org-pomodoro-state :overtime))
      (org-pomodoro-finished))
     ;; Maybe kill running pomodoro
     ((org-pomodoro-active-p)
      (if (or (not org-pomodoro-ask-upon-killing)
              (y-or-n-p "There is already a running timer.  Would you like to stop it? "))
          (el-patch-wrap 2 0 (progn (setq my-killed-pomodoro-time (/ (org-pomodoro-remaining-seconds) 60)) (org-pomodoro-kill)))
        (message "Alright, keep up the good work!")))
     ;; or start and clock in pomodoro
     (t
      (cond
       (el-patch-remove ((equal arg '(4))
                         (let ((current-prefix-arg '(4)))
                           (call-interactively 'org-clock-in))))
       ((equal arg '(16))
        (call-interactively 'org-clock-in-last))
       ((memq major-mode (list 'org-mode 'org-journal-mode))
        (el-patch-swap (call-interactively 'org-clock-in) (org-clock-in)))
       ((eq major-mode 'org-agenda-mode)
        (org-with-point-at (org-get-at-bol 'org-hd-marker)
          (call-interactively 'org-clock-in)))
       (t (let ((current-prefix-arg '(4)))
            (call-interactively 'org-clock-in))))
      (el-patch-wrap 3 0 (if (equal arg '(4))
                             (let ((org-pomodoro-length my-killed-pomodoro-time))
                               (org-pomodoro-start :pomodoro))
                           (org-pomodoro-start :pomodoro))))))
  (advice-add 'org-pomodoro-finished :around #'my-org-pomodoro-finished-with-overtime-advice)
  (advice-add 'org-pomodoro-kill :before #'my-org-pomodoro-clockout-before-kill-advice))


(use-package evil-org
  :ensure t
  :hook (org-mode . evil-org-mode)
  :init
  (evil-mode 1)
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys)
  (evil-org-set-key-theme '(navigation insert textobjects additional calendar shift todo heading)))


(defun my-anki-editor-make-heading-note ()
  "Set note type and note deck for heading at point."
  (interactive)
  (call-interactively #'anki-editor-set-deck)
  (call-interactively #'anki-editor-set-note-type))

(use-package anki-editor
  :ensure t
  :hook (org-noter-notes-mode . anki-editor-mode)
  :general-config
  (anki-editor-mode-map
   "C-c a ?" 'anki-editor-ui
   "C-c a h" 'my-anki-editor-make-heading-note
   "C-c a I" 'anki-editor-insert-note
   "C-c a i" 'anki-editor-insert-default-note
   "C-c a p" 'anki-editor-push-notes
   "C-c a r" 'anki-editor-delete-note-at-point
   "C-c a n" 'anki-editor-push-note-at-point))


;;;; org babel
(use-package plantuml-mode
  :ensure t
  :init
  (setopt
   org-plantuml-jar-path (concat user-emacs-directory "plantuml.jar")
   plantuml-jar-path (concat user-emacs-directory "plantuml.jar")) 
  :config
  (if (not (file-exists-p org-plantuml-jar-path))
      (plantuml-download-jar)))

(use-package graphviz-dot-mode
  :ensure t)

;; (use-package org-mindmap
;;   :after org
;;   :init
;;   (require 'org-mindmap)
;;   :general
;;   (org-mode-map
;;    "C-c m c" 'org-mindmap-insert-child
;;    "C-c m s" 'org-mindmap-insert-sibling
;;    "C-c m r" 'org-mindmap-insert-root
;;    "C-c m d" 'org-mindmap-delete-node
;;    "C-c m v" 'org-mindmap-switch-layout
;;    "C-c m m" 'org-mindmap-list-to-mindmap
;;    "C-c m l" 'org-mindmap-to-list)
;;   :config
;;   (defun my-org-mindmap-tab-advice (orig-fun &rest args)
;;     (let ((node (org-mindmap-find-node-at-point)))
;;       (if node
;;           (org-mindmap-insert-child)
;;         (apply orig-fun args))))
;;   (advice-add 'smart-tab :around #'my-org-mindmap-tab-advice))


(use-package ob-racket
  :ensure (:host github :repo "hasu/emacs-ob-racket")
  :hook (ob-racket-pre-runtime-library-load-hook . ob-racket-raco-make-runtime-library))

(use-package racket-mode
  :ensure t)

(use-package ob-html
  :ensure (:host github :repo "misohena/ob-html"))
;;; better help 


(defun my-persist-eldoc (interactive)
  (interactive (list t))
  (let ((mode major-mode))
    (if (get-buffer "*persisted eldoc*")
        (kill-buffer "*persisted eldoc*"))
    (with-current-buffer eldoc--doc-buffer
      (let ((s (string-replace " " " " (buffer-string))))
        (with-current-buffer (generate-new-buffer "*persisted eldoc*")
          (insert s)
          (visual-line-mode)
          (display-buffer (current-buffer))
          (set-window-start (get-buffer-window "*persisted eldoc*") 0)
          (general-def 'normal 'local
            "q" 'evil-window-delete))))))

(defun my-help-at-point ()
  (interactive)
  (cond
   ((and (featurep 'eglot) eglot--managed-mode) 
    (call-interactively #'my-persist-eldoc))
   ((equal major-mode 'inferior-python-mode)
    (my-python-eldoc-at-point))
   ((featurep 'helpful)
    (save-selected-window (helpful-at-point)))
   (t (message "No help at point provider"))))

(defun my-helpful-callable-save-window ()
  (interactive)
  (save-selected-window (call-interactively 'helpful-callable)))

(defun my-helpful-variable-save-window ()
  (interactive)
  (save-selected-window (call-interactively 'helpful-variable)))

(defun my-helpful-key-save-window ()
  (interactive)
  (save-selected-window (call-interactively 'helpful-key)))

(defun my-helpful-command-save-window ()
  (interactive)
  (save-selected-window (call-interactively 'helpful-command)))

(defun my-helpful-function-save-window ()
  (interactive)
  (save-selected-window (call-interactively 'helpful-function)))


(use-package helpful
  :ensure t
  :demand t
  :init
  (advice-add 'helpful-update :after #'elisp-demos-advice-helpful-update)
  :general-config
  (help-map
   "f" 'my-helpful-callable-save-window
   "v" 'my-helpful-variable-save-window
   "k" 'my-helpful-key-save-window
   "x" 'my-helpful-command-save-window
   "F" 'my-helpful-function-save-window)
  ('normal
   "g h" 'my-help-at-point)
  (help-map
   "." 'my-help-at-point))



(use-package elisp-demos
  :ensure t)
;;; better docs


(use-package pdf-tools
  :ensure t
  :hook
  (pdf-view-mode . pdf-view-roll-minor-mode)
  :init
  (pdf-tools-install t)
  :general-config
  ('(normal visual) pdf-annot-minor-mode-map
   "<return>" '("pdf-annot-mark-highlight". (lambda () (interactive) (pdf-annot-add-highlight-markup-annotation (pdf-view-active-region t) "#baa60e")))
   "C-c 1" '("pdf-annot-mark-understand". (lambda () (interactive) (pdf-annot-add-highlight-markup-annotation (pdf-view-active-region t) "#3d7f4d")))
   "C-c 2" '("pdf-annot-mark-keyword". (lambda () (interactive) (pdf-annot-add-strikeout-markup-annotation (pdf-view-active-region t) "blue")))
   "C-c 3" '("pdf-annot-mark-sentence". (lambda () (interactive) (pdf-annot-add-underline-markup-annotation (pdf-view-active-region t) "DarkViolet")))
   "C-c 4" '("pdf-annot-mark-argument" . (lambda () (interactive) (pdf-annot-add-squiggly-markup-annotation (pdf-view-active-region t) "red")))
   "r" 'pdf-annot-delete
   "d" 'pdf-annot-delete
   "t" 'pdf-annot-add-text-annotation)
  ('(normal visual) pdf-view-mode-map
   "C-f" 'pdf-view-next-page
   "C-b" 'pdf-view-previous-page
   "C-e" 'pdf-roll-scroll-forward
   "C-y" 'pdf-roll-scroll-backward)
  )

(use-package saveplace-pdf-view
  :ensure t
  :after (:any doc-view pdf-tools)
  :demand t)


(use-package org-remark
  :ensure t
  :hook
  (Info-mode . org-remark-info-mode)
  :config
  (org-remark-create "understand"
                     '(:background "#3d7f4d"))
  (org-remark-create "keyword"
                     '(:strike-through "blue"))
  (org-remark-create "sentence"
                     '(:underline "DarkViolet"))
  (org-remark-create "argument"
                     '(:overline "red"))
  (org-remark-create "highlight"
                     '(:foreground "#baa60e"))
  :general-config
  ('visual org-remark-mode-map
           "<return>" 'org-remark-mark-highlight
           "C-c 1" 'org-remark-mark-understand
           "C-c 2" 'org-remark-mark-keyword
           "C-c 3" 'org-remark-mark-sentence
           "C-c 4" 'org-remark-mark-argument)
  ('normal org-remark-mode-map
           "o" 'org-remark-open
           "]m" 'org-remark-view-next
           "[m" 'org-remark-view-prev
           "r" 'org-remark-delete
           "d" 'org-remark-delete)
  )

(defun my-file-extension (filename)
  (if (string-match "\\(?:\\.[A-Za-z]+\\)+$" filename)
      (let* ((file-extension (match-string 0 filename))
             (file-extension-list (split-string file-extension "\\." t)))
        file-extension-list)
    nil))



(use-package info
  :config
  (add-to-list 'Info-directory-list "/usr/share/info")
  (add-to-list 'Info-directory-list "/usr/local/share/info")
  (add-to-list 'Info-directory-list (concat user-emacs-directory "info/"))
  (el-patch-defun Info-find-node (filename nodename &optional no-going-back strict-case
                                           noerror)
    "Go to an Info node specified as separate FILENAME and NODENAME.
NO-GOING-BACK is non-nil if recovering from an error in this function;
it says do not attempt further (recursive) error recovery.

This function first looks for a case-sensitive match for NODENAME;
if none is found it then tries a case-insensitive match (unless
STRICT-CASE is non-nil).

If NOERROR, inhibit error messages when we can't find the node."
    (info-initialize)
    (setq nodename (info--node-canonicalize-whitespace nodename))
    (setq filename (Info-find-file filename noerror))
    ;; Go into Info buffer.
    (or (derived-mode-p 'Info-mode) (info-pop-to-buffer filename))
    ;; Record the node we are leaving, if we were in one.
    (and (not no-going-back)
         Info-current-file
         (push (list Info-current-file Info-current-node (point))
               Info-history))
    
    (el-patch-wrap 3 0 (if-let* ((filename filename)
                                 (extension (my-file-extension filename))
                                 (info (not (member "info" extension))))
                           (let ((buffer (find-file-noselect filename)))
                             (switch-to-buffer buffer)
                             (require 'general)
                             (general-def 'normal 'local
                               "u" 'info))
                         (Info-find-node-2 filename nodename no-going-back strict-case))))

  )


(use-package devdocs
  :ensure t
  :general
  (help-map
   "D" 'devdocs-peruse)
  :general-config
  ('normal devdocs-mode-map
           "C-o" 'devdocs-go-back
           "C-i" 'devdocs-go-forward
           "C-j" 'devdocs-next-page
           "C-k" 'devdocs-previous-page
           "i" 'devdocs-lookup)
  )

(defvar org-noter-toggle-sync t)

(defun org-noter-toggle-sync ()
  "Toggle `org-noter-toggle-sync'"
  (interactive)
  (if org-noter-toggle-sync
      (progn (message "Off")
             (setq org-noter-toggle-sync nil))
    (message "On")
    (setq org-noter-toggle-sync t)))

(defun org-noter-toggle-advice (orig-fun &rest args)
  (if org-noter-toggle-sync
      (apply orig-fun args)
    nil))

(use-package org-noter
  :ensure t
  :init
  (setopt
   org-noter-auto-save-last-location t)
  :general
  ('(visual normal) org-noter-doc-mode-map
   "i" 'org-noter-insert-note
   "q" 'org-noter-kill-session
   "c" 'org-noter-toggle-sync)
  (org-mode-map
   "C-c n" 'org-noter)
  :config
  (advice-add 'org-noter--doc-location-change-handler :around #'org-noter-toggle-advice)
  )
;;; git

(use-package transient
  :ensure t)

(use-package magit
  :ensure t
  :init
  (setopt
   magit-display-buffer-function 'magit-display-buffer-same-window-except-diff-v1)
  :general
  ("C-c g" 'magit-dispatch
   "C-c f" 'magit-file-dispatch)
  :general-config
  ('(visual normal) magit-mode-map
   "] ]" 'magit-section-forward
   "[ [" 'magit-section-backward)
  ('normal magit-section-mode-map
           "] ]" 'magit-section-forward
           "[ [" 'magit-section-backward))


(use-package diff-hl
  :ensure t
  :init
  (global-diff-hl-mode)
  (setopt
   diff-hl-show-staged-changes nil)
  :general-config
  ('(visual normal)
   "] g" 'diff-hl-next-hunk
   "[ g" 'diff-hl-previous-hunk
   "] G" 'diff-hl-show-hunk-next
   "[ G" 'diff-hl-show-hunk-previous ))
;;; docker

(use-package docker
  :ensure t
  :init
  (setopt
   docker-command "docker"))
(use-package dockerfile-mode
  :ensure t)
;;; language servers
(use-package mason
  :ensure t
  :demand t
  :config
  (mason-ensure
   (lambda ()
     (ignore-errors (mason-install "texlab"))))
  (mason-ensure
   (lambda ()
     (ignore-errors (mason-install "ty"))))
  (mason-ensure
   (lambda ()
     (ignore-errors (mason-install "csharp-language-server"))))
  (mason-ensure
   (lambda ()
     (ignore-errors (mason-install "clangd"))))
  (mason-ensure
   (lambda ()
     (ignore-errors (mason-install "typescript-language-server"))))
  (mason-ensure
   (lambda ()
     (ignore-errors (mason-install "eslint-lsp"))))
  (mason-ensure
   (lambda ()
     (ignore-errors (mason-install "tailwindcss-language-server"))))
  (mason-ensure
   (lambda ()
     (ignore-errors (mason-install "jdtls")))))
;;; php


(use-package php-mode
  :ensure t
  :mode ("\\.php\\'" . php-ts-mode)
  )
;;; latex




(use-package eglot
  :hook
  (LaTeX-mode . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               '(LaTeX-mode . ("texlab")))
  )

(use-package tex
  :init
  (setopt
   TeX-auto-save t
   TeX-parse-self t))

(use-package auctex
  :ensure t)
;; (use-package latex
;;   :config
;;   (modify-syntax-entry ?$ "\"" LaTeX-mode-syntax-table))

;;; python





(use-package eglot
  :hook
  (python-ts-mode . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode) "ty" "server")))

(defun my-python-repl ()
  "Go to Python REPL and create it if needed."
  (interactive)
  (if (python-shell-get-buffer)
      (python-shell-switch-to-shell)
    (run-python "python3 -i" nil t)))

(defun my-python-eldoc-at-point ()
  "Get python documentation in eldoc with `python-eldoc--get-doc-at-point'."
  (interactive)
  (call-interactively 'eldoc-doc-buffer)
  (eldoc-display-in-buffer `((,(python-eldoc-function))) nil)
  )

(defun my-override-evil-collection-python (mode &rest _rest)
  "Keybinds for overriding evil-collection-python."
  (general-def 'normal python-ts-mode-map
    "g z" 'my-python-repl))

(use-package python
  :hook (evil-collection-setup . my-override-evil-collection-python)
  :general-config
  (python-ts-mode-map
   "C-c C-n" 'python-shell-send-defun)
  (inferior-python-mode-map
   "C-c ?" 'my-python-eldoc-at-point)
  ('normal python-ts-mode-map
           "=" (general-key-dispatch 'evil-indent
                 "=" 'my-format-buffer))
  :config
  (advice-add 'python-shell-completion-at-point :around
              (lambda (fun &optional arg)
                (cape-wrap-noninterruptible (lambda () (funcall fun arg))))))

;; (use-package eglot-python-preset
;;   :after eglot
;;   :init
;;   (require 'project)
;;   (setopt
;;    eglot-python-preset-lsp-server 'ty)
;;   :config
;;   (eglot-python-preset-setup))

(use-package pet
  :ensure t
  :init
  (add-hook 'python-base-mode-hook 'pet-mode -10))

(use-package treesit-auto
  :ensure t
  :demand t
  :init
  (setopt
   treesit-font-lock-level 4)
  :config
  (delete 'yaml treesit-auto-langs)
  (global-treesit-auto-mode))


(use-package py-isort
  :ensure t)


(use-package slime-star
  :ensure `(:host github :repo "mmontone/slime-star"
                  :build (:after elpaca-source
                                 ,(elpaca-defscript +elpaca-update-submodules (:type system)
                                    ("git" "submodule" "update" "--init" "--recursive")))))



(use-package slime
  :ensure (:host github :repo "slime/slime" :tag "v2.32"))

(use-package slime-py
  :ensure (:host codeberg :repo "sczi/swanky-python" :files (:defaults "slimy-python/*.el"))
  :init
  (setq inferior-lisp-program "sbcl")
  (add-to-list 'load-path (concat user-emacs-directory "elpaca/sources/slime-star/"))
  (add-to-list 'load-path (concat user-emacs-directory "elpaca/sources/swanky-python/slimy-python/"))
  (setq slime-contribs '(slime-py slime-fancy slime-star slime-asdf slime-sprof slime-tramp))
  )



;;; csharp




(use-package eglot
  :hook
  (csharp-ts-mode . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               '((csharp-mode csharp-ts-mode) "csharp-ls" "-f" "metadata-uris"))
  )
(use-package sharper
  :ensure t
  :general-config
  ('normal sharper--project-packages-mode-map
           "g r" 'sharper--project-packages-refresh
           "?" 'sharper-transient-project-packages)
  ('normal sharper--project-references-mode-map
           "g r" 'sharper--project-references-refresh
           "?" 'sharper-transient-project-references))

;; TODO
(cl-defun my-eglot--lsp-xrefs-for-metadata ()
  "Make `xref''s for metadata uri's returned from `:textDocument/definition' by calling `:csharp/metadata' for csharp-ls language server."
  (let* ((metadata
          (eglot--request
           (eglot--current-server-or-lose)
           :textDocument/definition (append (eglot--TextDocumentPositionParams))))
         (uri (plist-get (aref metadata 0) :uri))
         (decompile
          (eglot--request
           (eglot--current-server-or-lose) :csharp/metadata (list :timeout 5000 :textDocument (list :uri uri)))))
    )
  )

(use-package csharp-mode

  :general-config
  (csharp-ts-mode-map
   "C-c s" 'sharper-main-transient))


;;; c




(use-package eglot
  :hook
  (c-ts-mode . eglot-ensure))

;;; javascript


(use-package ts
  :mode ("\\.tsx\\'" . js-ts-mode)
  :hook
  ((astro-ts-mode jtsx-jsx-mode jtsx-tsx-mode jtsx-typescript-mode
                  js-mode js-ts-mode typescript-ts-mode tsx-ts-mode css-mode css-ts-mode svelte-mode svelte-ts-mode vue-mode vue-ts-mode) . eglot-ensure))

(use-package eglot-typescript-preset
  :ensure t
  :init
  (setopt
   eglot-typescript-preset-lsp-server 'rass))




;;; emacs lisp

(defun my-elisp-imenu ()
  "Set up imenu for elisp."
  (setq imenu-generic-expression (append (list  (list "Use Package" "(use-package \\(.+\\)" 1)) imenu-generic-expression)))

(use-package elisp-mode

  :hook (emacs-lisp-mode . my-elisp-imenu))


;;; sql


(use-package sql
  :mode ("\\.sql\\'" . sql-mode))

(use-package sql-indent
  :ensure t
  :hook
  (sql-mode . sqlind-minor-mode))
;;; yaml

(use-package yaml-mode
  :ensure t
  :mode ("\\.yml\\'" . yaml-mode)
  :mode ("\\.yaml\\'" . yaml-mode)
  )
;;; java



(defun jdtls-reload-project-config (&optional server)
  "Tell jdtls to reload the server configuration.  Useful after build system
changes."
  (interactive)
  (let ((truename (file-truename (or buffer-file-name
                                     (ignore-errors
                                       (buffer-file-name
                                        (buffer-base-buffer))))))
        (srv (or server (eglot-current-server))))
    (jsonrpc-notify srv
                    :java/projectConfigurationUpdate
                    `(:uri ,(eglot-path-to-uri truename :truenamep t)))))
(use-package eglot
  :hook
  (java-ts-mode . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               `((java-mode java-ts-mode) .
                 (,(expand-file-name (concat user-emacs-directory "mason/bin/jdtls"))
                  ,(concat "--jvm-arg=-javaagent:"
                           (expand-file-name (concat user-emacs-directory "mason/packages/jdtls/lombok.jar")))
                  "-data" ,(expand-file-name "~/.cache/emacs/jdtls-workspace")
                  :initializationOptions
                  (:bundles
                   [,(expand-file-name
                      (concat user-emacs-directory "bin/java-debug-0.53.1/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-0.53.1.jar"))])))))



;;; debugging


(defun my-dape-watch-dwim ()
  "Call dape-watch-dwim without opening dape-info watch."
  (interactive)
  (save-window-excursion (call-interactively #'dape-watch-dwim)))

(use-package dape
  :ensure t
  :hook 
  (kill-emacs . dape-breakpoint-save)
  (after-init . dape-breakpoint-load)
  (dape-display-source . pulse-momentary-highlight-one-line)
  (dape-start . (lambda () (save-some-buffers t t)))
  (dape-compile . kill-buffer)
  (python-ts-mode . dape-breakpoint-global-mode)
  (csharp-ts-mode . dape-breakpoint-global-mode)
  :custom
  (dape-key-prefix nil)
  :init
  (setopt
   dape-buffer-window-arrangement 'gud
   dape-info-hide-mode-line nil)
  :config
  (push (cons '("Z Q" . nil)
              (lambda (kb)
                (cons (car kb)
                      (if dape-active-mode
                          "dape-quit"
                        "evil-quit"))))
        which-key-replacement-alist)
  :general-config
  ('normal 'override
           :predicate 'dape-active-mode
           "Z Q" '("dape-quit" . dape-quit))
  ('(normal insert) 'override
   :predicate 'dape-active-mode
   "<f5>" 'dape-continue
   "<f6>" 'dape-step-out
   "<f7>" 'dape-step-in
   "<f8>" 'dape-next)
  (python-ts-mode-map
   "C-c B" 'dape-breakpoint-remove-all
   "C-c r" 'dape-repl
   "C-c b" 'dape-breakpoint-toggle
   "C-c e" 'dape-breakpoint-expression
   "C-c h" 'dape-breakpoint-hits
   "C-c i" 'dape-info
   "C-c l" 'dape-breakpoint-log
   "C-c q" 'dape-quit
   "C-c w" 'my-dape-watch-dwim)
  (csharp-ts-mode-map
   "C-c B" 'dape-breakpoint-remove-all
   "C-c r" 'dape-repl
   "C-c b" 'dape-breakpoint-toggle
   "C-c e" 'dape-breakpoint-expression
   "C-c h" 'dape-breakpoint-hits
   "C-c i" 'dape-info
   "C-c l" 'dape-breakpoint-log
   "C-c q" 'dape-quit
   "C-c w" 'my-dape-watch-dwim))

(use-package edebug
  :config
  (setq edebug-mode-map (make-sparse-keymap))
  :general-config
  ('(insert normal) edebug-mode-map
   "<f8>" 'edebug-step-mode
   "<f5>" 'edebug-go-mode
   "<f6>" 'edebug-step-out
   "<f7>" 'edebug-step-in)
  ('normal edebug-mode-map
           "Z Q" 'top-level
           "q" 'top-level)
  (edebug-mode-map
   ;; windows
   "C-c w"       'edebug-toggle-save-windows
   ;; quitting and stopping
   "C-c q"       'top-level

   ;; breakpoints
   "C-c b"       'edebug-set-breakpoint
   "C-c u"       'edebug-unset-breakpoint
   "C-c U"       'edebug-unset-breakpoints
   "C-c B"       'edebug-next-breakpoint
   "C-c x"       'edebug-set-conditional-breakpoint
   "C-c X"       'edebug-set-global-break-condition
   "C-c D"       'edebug-toggle-disable-breakpoint

   ;; evaluation
   "C-c r"       'edebug-previous-result
   "C-c e"       'edebug-eval-expression
   "C-c C-x C-e" 'edebug-eval-last-sexp
   "C-c E"       'edebug-visit-eval-list

   ;; misc
   "C-c ?"       'edebug-help)
  ('(normal insert) edebug-eval-mode-map
   "RET" 'edebug-update-eval-list))


;;; language server completion backends documentation output


(defvar my-eglot-completion-functions (list #'yasnippet-capf #'eglot-completion-at-point)
  "The list of completion functions to combine to replace `eglot-completion-at-point'.")

(defun my-eglot-capf ()
  "Configure `completion-at-point-functions' to replace `eglot-completion-at-point' with completion results including all completions in `my-eglot-capf'."
  ;; Remember that local values in completion-at-point-functions take priority over global values."
  (setq-local completion-at-point-functions
              (list (apply 'cape-capf-super my-eglot-completion-functions))))

(defun my-file-completion-for-eglot ()
  "Give `cape-file' priority in `completion-at-point-functions'."
  ;; Remember that local values in completion-at-point-functions take priority over global values."
  (add-hook 'completion-at-point-functions #'cape-file -100 t))

(use-package eglot
  :init
  (load "project.elc")
  :config
  (setopt
   eglot-connect-timeout 60)
  (add-to-list 'exec-path (concat user-emacs-directory "mason/bin/"))
  (add-hook 'eglot-managed-mode-hook #'my-eglot-capf)
  (add-hook 'eglot-managed-mode-hook #'my-file-completion-for-eglot 100)
  ;; if lsp-server returns many completions then turn off but if it doesn't then turn it on
  ;; This line causes function to delete or add characters when exiting https://github.com/minad/cape/issues/81
  ;; (advice-add #'eglot-completion-at-point :around #'cape-wrap-buster))
  )


(use-package eldoc
  :init
  (setopt
   eldoc-echo-area-prefer-doc-buffer t
   eldoc-echo-area-use-multiline-p nil)
  )


(use-package yasnippet
  :ensure t
  :init
  (setopt
   yas-also-auto-indent-first-line t)
  (yas-global-mode 1)
  :general-config
  (yas-keymap
   "<tab>" nil
   "TAB" nil
   "C-<tab>" 'yas-next-field
   "C-<iso-lefttab>" 'yas-prev-field))

(use-package yasnippet-snippets
  :ensure t)
(use-package markdown-mode
  :ensure t)
;;; default completion backends 


(defun my-hippie-expand-advice (orig-fun &rest args)
  (let ((case-fold-search nil))
    (apply orig-fun args)))

(use-package hippie-exp
  :custom
  (hippie-expand-try-functions-list '(try-expand-dabbrev try-expand-dabbrev-all-buffers try-expand-dabbrev-from-kill try-complete-file-name-partially try-complete-file-name try-expand-all-abbrevs try-expand-list try-expand-line try-complete-lisp-symbol-partially try-complete-lisp-symbol))
  :config
  (advice-add 'hippie-expand :around #'my-hippie-expand-advice)
  )


(defun my-yasnippet-add-completion-functions ()
  "Add yasnippet-capf to `completion-at-point-functions'."
  ;; Note that the list of buffer-local
  ;; completion functions takes precedence over the global list.
  ;; Add yasnippet-capf globally
  (add-to-list 'completion-at-point-functions #'yasnippet-capf)
  )

(use-package yasnippet-capf
  :ensure t
  :hook ((prog-mode org-mode) . my-yasnippet-add-completion-functions)
  )

(use-package cape
  :ensure t
  :init
  (add-to-list 'completion-at-point-functions #'cape-file))

;;; completion middle end


(use-package orderless
  :ensure t
  :init
  (setopt
   completion-styles '(orderless partial-completion basic)
   completion-category-defaults nil
   completion-category-overrides '((file (styles partial-completion)))))
;;; completion frontends

(use-package corfu
  :ensure t
  :init
  (setopt
   corfu-cycle t
   corfu-on-exact-match 'quit
   corfu-quit-no-match 'separator
   corfu-preview-current 'nil
   corfu-preselect 'first
   corfu-auto t
   corfu-auto-prefix 2
   corfu-auto-delay 0.2
   corfu-min-width 80
   corfu-max-width corfu-min-width
   corfu-count 14
   corfu-scroll-margin 4
   global-corfu-minibuffer nil
   corfu-popupinfo-delay nil)
  (global-corfu-mode)
  (corfu-history-mode)
  (corfu-popupinfo-mode)
  :general-config
  (corfu-map
   "M-SPC" 'corfu-insert-separator
   "RET" nil
   )
  ('insert corfu-map
           "M-k" 'corfu-scroll-down
           "M-j" 'corfu-scroll-up)
  (corfu-popupinfo-map
   "C-h" 'corfu-popupinfo-toggle
   "C-S-j" 'corfu-popupinfo-scroll-up
   "C-S-k" 'corfu-popupinfo-scroll-down))

(use-package vertico
  :ensure t
  :init
  (setopt
   vertico-cycle t)
  (vertico-mode)
  :config
  (eval-after-load "evil-maps"
    (dolist (map '(evil-insert-state-map))
      (define-key (eval map) "\C-k" nil)
      ))
  :general-config
  ('(insert normal) vertico-map
   "C-j" 'vertico-next
   "C-k" 'vertico-previous
   "C-S-j" 'scroll-up-command
   "C-S-k" 'scroll-down-command
   "C-b" 'evil-backward-char
   "C-f" 'evil-forward-char))

(use-package consult
  :ensure t
  :init
  (setopt completion-in-region-function 'consult-completion-in-region))

(use-package kind-icon
  :ensure t
  :init
  (setopt
   kind-icon-mapping
   '((array "a" :icon "code-brackets" :face font-lock-type-face)
     (boolean "b" :icon "circle-half-full" :face
              font-lock-builtin-face)
     (class "c" :icon "view-grid-plus-outline" :face
            font-lock-type-face)
     (color "#" :icon "palette" :face success)
     (command "cm" :icon "code-greater-than" :face default)
     (constant "co" :icon "lock-remove-outline" :face
               font-lock-constant-face)
     (constructor "cn" :icon "table-column-plus-after" :face
                  font-lock-function-name-face)
     (enummember "em" :icon "order-bool-ascending-variant" :face
                 font-lock-builtin-face)
     (enum-member "em" :icon "order-bool-ascending-variant" :face
                  font-lock-builtin-face)
     (enum "e" :icon "format-list-bulleted-square" :face
           font-lock-builtin-face)
     (event "ev" :icon "lightning-bolt-outline" :face
            font-lock-warning-face)
     (field "fd" :icon "application-braces-outline" :face
            font-lock-variable-name-face)
     (file "f" :icon "file-document-outline" :face
           font-lock-string-face)
     (folder "d" :icon "folder" :face font-lock-doc-face)
     (interface "if" :icon "application-brackets-outline" :face
                font-lock-type-face)
     (keyword "kw" :icon "key-variant" :face font-lock-keyword-face)
     (macro "mc" :icon "lambda" :face font-lock-keyword-face)
     (magic "ma" :icon "auto-fix" :face font-lock-builtin-face)
     (method "m" :icon "function-variant" :face
             font-lock-function-name-face)
     (function "f" :icon "function" :face font-lock-function-name-face)
     (module "{" :icon "file-code-outline" :face
             font-lock-preprocessor-face)
     (numeric "nu" :icon "numeric" :face font-lock-builtin-face)
     (operator "op" :icon "plus-minus" :face
               font-lock-comment-delimiter-face)
     (param "pa" :icon "cog" :face default)
     (property "pr" :icon "wrench" :face font-lock-variable-name-face)
     (reference "rf" :icon "library" :face
                font-lock-variable-name-face)
     (snippet "S" :icon "content-cut" :face font-lock-string-face)
     (string "s" :icon "sticker-text-outline" :face
             font-lock-string-face)
     (struct "%" :icon "code-braces" :face
             font-lock-variable-name-face)
     (text "tx" :icon "script-text-outline" :face font-lock-doc-face)
     (typeparameter "tp" :icon "format-list-bulleted-type" :face
                    font-lock-type-face)
     (type-parameter "tp" :icon "format-list-bulleted-type" :face
                     font-lock-type-face)
     (unit "u" :icon "ruler-square" :face font-lock-constant-face)
     (value "v" :icon "plus-circle-outline" :face
            font-lock-builtin-face)
     (variable "va" :icon "variable" :face
               font-lock-variable-name-face)
     (t "." :icon "crosshairs-question" :face font-lock-warning-face)))
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter)
  )
(use-package marginalia
  :ensure t
  :init
  (marginalia-mode))
;;; windows

(use-package burly
  :ensure t)

(use-package space-tree
  :ensure (:host github :repo "chiply/space-tree")
  :demand t
  :config
  (space-tree-init)
  (el-patch-defun space-tree--modeline-string-for-level
    (parent-address selected-space-number spaces-at-this-level)
    "Render one level of the modeline lighter as a string.

PARENT-ADDRESS is the address of the parent node, used to look up
named spaces.  SELECTED-SPACE-NUMBER is the number, at this level,
that lies on the current address; it is rendered in bold with a
trailing apostrophe.  SPACES-AT-THIS-LEVEL is the hash table of
sibling nodes at this level."
    (mapconcat
     (lambda (n)
       (let ((label (or (gethash (append parent-address (list n))
			         space-tree-space-name-tbl)
		        (number-to-string n))))
         (if (equal n selected-space-number)
	     (propertize (concat label "' ") 'face (el-patch-swap 'bold 'mode-line-highlight))
	   (concat label " "))))
     (sort (hash-table-keys spaces-at-this-level) #'<)
     ""))
  :general
  ('(normal insert) 
   "s-1" #'space-tree-to-1
   "s-2" #'space-tree-to-2
   "s-3" #'space-tree-to-3
   "s-4" #'space-tree-to-4
   "s-5" #'space-tree-to-5
   "s-6" #'space-tree-to-6
   "s-7" #'space-tree-to-7
   "s-8" #'space-tree-to-8
   "s-9" #'space-tree-to-9

   ;; Second level (within current top-level space)
   "s-a" #'space-tree-sub-1
   "s-s" #'space-tree-sub-2
   "s-d" #'space-tree-sub-3
   "s-f" #'space-tree-sub-4
   "s-g" #'space-tree-sub-5

   ;; Third level (within current second-level space)
   "s-A" #'space-tree-sub-sub-1
   "s-S" #'space-tree-sub-sub-2
   "s-D" #'space-tree-sub-sub-3
   "s-F" #'space-tree-sub-sub-4
   "s-G" #'space-tree-sub-sub-5

   ;; Navigation
   ;; "C-S-<iso-lefttab>"   #'space-tree-switch-space-by-name
   "C-S-<iso-lefttab>"     #'space-tree-go-to-last-space
   ;; "C-M-<tab>"   #'space-tree-go-right
   ;; "C-M-S-<tab>" #'space-tree-go-left

   ;; Delete current space (the command defaults to the current address)
   "s-_" #'space-tree-delete-space))

(use-package popper
  :ensure t
  :init
  (setopt
   popper-display-control 'user
   popper-reference-buffers
   '("\\*Messages\\*"
     "Output\\*$"
     "\\*Async Shell Command\\*"
     "\\*eshell\\*"
     "\\*Outline"
     "\\*dotnet"
     "events\\*"
     "\\*shell\\*"
     "\\*dape-shell\\*" 
     "\\*Warnings\\*"
     "\\*vterm\\*"
     "^\\* docker.+ up"
     "^\\* docker.+ exec"
     "^\\* docker vterm"
     "\\* docker container logs"
     "\\*slime-repl uv-python"
     "\\*Racket"
     "\\*sldb"
     "\\*xref\\*"
     "\\*Backtrace\\*"
     "\\*Occur\\*"
     "\\*ghostel"
     (lambda (buf) (with-current-buffer buf
                     (derived-mode-p 'comint-mode)))
     debugger-mode
     compilation-mode
     diff-mode
     ))
  (popper-mode 1)
  (popper-echo-mode 1))

(defun my-fit-window-to-buffer (&optional window max-height min-height max-width min-width preserve-size)
  (let* ((wind (if window window (selected-window)))
         (initial-width (window-width wind))
         (initial-height (window-height window)))
    (fit-window-to-buffer window max-height min-height max-width min-width preserve-size)
    (if (or (not (equal (window-width wind) initial-width)) (not (equal (window-height wind) (window-height wind))))
        t
      nil)))

(defun my-fit-window-to-right-side (window)
  "Use `fit-window-to-buffer' with right side window specifications."
  (let ((max-width (floor (* 0.35 (frame-width))))
        (max-height (floor (* 0.50 (frame-height)))))
    (if (my-fit-window-to-buffer window max-height window-min-height max-width)
        nil
      (window-resize window (- max-width (window-width window)) t)
      (window-resize window (- max-height (window-height window))))))


;; TODO
(defun my-fit-window-to-magit (window)
  "Use 'fit-window-to-buffer' but make it work for magit's behavior."
  (let ((max-width (floor (* 0.50 (frame-width))))
        (max-height (floor (* 1.00 (frame-height)))))
    (fit-window-to-buffer window max-height window-min-height max-width)))

(use-package window
  :init
  (setopt
   menu-bar-mode nil
   fit-window-to-buffer-horizontally t
   tab-bar-mode nil
   tool-bar-mode nil
   line-number-mode nil
   switch-to-buffer-in-dedicated-window 'pop
   switch-to-buffer-obey-display-actions nil
   window-sides-slots '(2 2 2 2))
  :config
  (setq display-buffer-alist
        '(
          ((or "\\*info\\*" (major-mode . eww-mode) "\\*devdocs\\*")
           (display-buffer-reuse-window display-buffer-in-side-window)
           (side . right)
           (slot . 0)
           (window-width . my-fit-window-to-right-side))
          ("\\*helpful\\|\\*Help\\*\\|\\*eldoc\\*\\|\\*persisted eldoc\\*"
           (display-buffer-reuse-window display-buffer-in-side-window)
           (side . right)
           (slot . -1)
           (window-width . my-fit-window-to-right-side))
          ((or "\\*dotnet\\|\\*Messages\\*\\|Output\\*\\|events\\*\\|\\*eshell\\*\\|\\*shell\\*\\|\\*dape-shell\\*\\|\\*vterm\\*\\|^\\* docker.+ up\\|^\\* docker.+ exec\\|\\*Racket\\|^\\* docker vterm\\|\\*slime-repl uv-python\\|\\*sldb\\|\\*xref\\*\\|\\* docker container logs\\|\\*Outline\\|\\*Warnings\\*\\|\\*Backtrace\\*\\|\\*Occur\\*\\|\\*ghostel" (major-mode . compilation-mode)  (major-mode . debugger-mode) (derived-mode . comint-mode) (major-mode . diff-mode)) 
           (display-buffer-reuse-window display-buffer-in-side-window)
           (side . bottom)
           (slot . 0)
           (window-height . 0.50))
          
          )))


;;; visual non-functional changes


(use-package indent-bars
  :ensure t
  :hook
  (prog-mode . indent-bars-mode))

(use-package font-core
  :config
  (set-frame-font "JetBrains Mono 10" nil t)
  (setopt line-spacing 1))

;; (use-package minions
;;   :init
;;   (minions-mode 1))


(use-package simple
  :hook
  (visual-line-mode . visual-wrap-prefix-mode)
  ((helpful-mode info-mode diff-mode) . visual-line-mode)
  :init
  (setopt
   visual-line-fringe-indicators '(nill nill)))


(use-package bookmark
  :init
  (setopt bookmark-fringe-mark nil))

(use-package per-buffer-theme
  :ensure (:host github :repo "emacsmirror/per-buffer-theme")
  :init
  (setopt
   per-buffer-theme-default-theme 'modus-vivendi
   per-buffer-theme-default-font "JetBrains Mono 10"
   per-buffer-theme-themes-alist '(((:theme . modus-operandi-tinted)
                                    (:font "JetBrains Mono 10")
                                    (:modes inferior-python-mode python-ts-mode python-mode))
                                   ((:theme . doric-almond)
                                    (:font "JetBrains Mono 10")
                                    (:modes astro-ts-mode jtsx-jsx-mode jtsx-tsx-mode jtsx-typescript-mode
                                            js-mode js-ts-mode typescript-ts-mode tsx-ts-mode css-mode css-ts-mode svelte-mode svelte-ts-mode vue-mode vue-ts-mode))
                                   ((:theme . modus-vivendi-tinted)
                                    (:font "JetBrains Mono 10")
                                    (:modes csharp-mode csharp-ts-mode))
                                   ((:theme . modus-operandi)
                                    (:font "JetBrains Mono 10")
                                    (:modes c-ts-mode))
                                   ((:theme . doric-siren)
                                    (:font "JetBrains Mono 10")
                                    (:modes sql-mode)))
   per-buffer-theme-ignored-buffernames-regex '("*[Mm]ini" "*helpful" "*info*" "magit" "COMMIT" "vterm" "notes.org" "*devdocs*" "*Async Shell Command" "Calc" "*persisted eldoc*" "docker" "sldb" "slime" "*Messages*" "*Ibuffer*" "*Help*" ".pdf" "*SQL:" "*compilation*" "*eshell*"))
  (per-buffer-theme-mode 1))

(use-package doric-themes
  :ensure t)

(use-package emacs
  :config
  (setopt project-mode-line t)
  (setq mode-line-modes
        '((compilation-in-progress
           #("[Compiling] " 0 12
             (help-echo "Compiling; mouse-2: Goto Buffer" mouse-face
                        mode-line-highlight local-map
                        (keymap
                         (mode-line keymap
                                    (mouse-2
                                     . compilation-goto-in-progress-buffer))))))
          #("%[" 0 2 (help-echo "Recursive edit, type C-M-c to get out")) "("
          (:propertize ("" mode-name) help-echo
                       "Major mode\nmouse-1: Display major mode menu\nmouse-2: Show help for major mode\nmouse-3: Toggle minor modes"
                       mouse-face mode-line-highlight local-map
                       (keymap
                        (mode-line keymap
                                   (down-mouse-3 menu-item "Minor Modes"
                                                 (keymap
                                                  (orgtbl-mode menu-item
                                                               "Org Table Mode"
                                                               orgtbl-mode
                                                               :button
                                                               (:toggle
                                                                . orgtbl-mode))
                                                  (abbrev-mode menu-item
                                                               "Abbrev (Abbrev)"
                                                               abbrev-mode
                                                               :help
                                                               "Automatically expand abbreviations"
                                                               :button
                                                               (:toggle
                                                                . abbrev-mode))
                                                  (auto-fill-mode menu-item
                                                                  "Auto fill (Fill)"
                                                                  auto-fill-mode
                                                                  :help
                                                                  "Automatically insert new lines"
                                                                  :button
                                                                  (:toggle
                                                                   . auto-fill-function))
                                                  (auto-revert-mode menu-item
                                                                    "Auto revert (ARev)"
                                                                    auto-revert-mode
                                                                    :help
                                                                    "Revert the buffer when the file on disk changes"
                                                                    :button
                                                                    (:toggle
                                                                     bound-and-true-p
                                                                     auto-revert-mode))
                                                  (auto-revert-tail-mode
                                                   menu-item
                                                   "Auto revert tail (Tail)"
                                                   auto-revert-tail-mode :help
                                                   "Revert the tail of the buffer when the file on disk grows"
                                                   :enable (buffer-file-name)
                                                   :button
                                                   (:toggle bound-and-true-p
                                                            auto-revert-tail-mode))
                                                  (completion-preview-mode
                                                   menu-item
                                                   "Completion Preview (CP)"
                                                   completion-preview-mode
                                                   :help
                                                   "Show preview of completion suggestions as you type"
                                                   :enable
                                                   completion-at-point-functions
                                                   :button
                                                   (:toggle bound-and-true-p
                                                            completion-preview-mode))
                                                  (flyspell-mode menu-item
                                                                 "Flyspell (Fly)"
                                                                 flyspell-mode
                                                                 :help
                                                                 "Spell checking on the fly"
                                                                 :button
                                                                 (:toggle
                                                                  bound-and-true-p
                                                                  flyspell-mode))
                                                  (font-lock-mode menu-item
                                                                  "Font Lock"
                                                                  font-lock-mode
                                                                  :help
                                                                  "Syntax coloring"
                                                                  :button
                                                                  (:toggle
                                                                   . font-lock-mode))
                                                  (glasses-mode menu-item
                                                                "Glasses (o^o)"
                                                                glasses-mode
                                                                :help
                                                                "Insert virtual separators to make long identifiers easy to read"
                                                                :button
                                                                (:toggle
                                                                 bound-and-true-p
                                                                 glasses-mode))
                                                  (hide-ifdef-mode menu-item
                                                                   "Hide ifdef (Ifdef)"
                                                                   hide-ifdef-mode
                                                                   :help
                                                                   "Show/Hide code within #ifdef constructs"
                                                                   :button
                                                                   (:toggle
                                                                    bound-and-true-p
                                                                    hide-ifdef-mode))
                                                  (highlight-changes-mode
                                                   menu-item
                                                   "Highlight changes (Chg)"
                                                   highlight-changes-mode :help
                                                   "Show changes in the buffer in a distinctive color"
                                                   :button
                                                   (:toggle bound-and-true-p
                                                            highlight-changes-mode))
                                                  (outline-minor-mode menu-item
                                                                      "Outline (Outl)"
                                                                      outline-minor-mode
                                                                      :help ""
                                                                      :button
                                                                      (:toggle
                                                                       bound-and-true-p
                                                                       outline-minor-mode))
                                                  (overwrite-mode menu-item
                                                                  "Overwrite (Ovwrt)"
                                                                  overwrite-mode
                                                                  :help
                                                                  "Overwrite mode: typed characters replace existing text"
                                                                  :button
                                                                  (:toggle
                                                                   . overwrite-mode))
                                                  "Minor Modes")
                                                 :filter
                                                 bindings--sort-menu-keymap)
                                   (mouse-2 . describe-mode)
                                   (down-mouse-1 menu-item "Menu Bar" ignore
                                                 :filter
                                                 #[257 "\300 \207"
                                                       [mouse-menu-major-mode-map]
                                                       2 "\n\n(fn _)"]))))
          ("" mode-line-process)
          #("%n" 0 2
            (help-echo "mouse-2: Remove narrowing from buffer" mouse-face
                       mode-line-highlight local-map
                       (keymap (mode-line keymap (mouse-2 . mode-line-widen)))))
          ")" #("%]" 0 2 (help-echo "Recursive edit, type C-M-c to get out"))
          " "
          (:eval (space-tree-modeline-lighter))
          " "))
  (setq-default
   mode-line-format '("%e" mode-line-front-space
                      (:propertize
                       ("" mode-line-modified))
                      ;; (:propertize
                      ;;  ("" mode-line-mule-info mode-line-client mode-line-modified
                      ;;   mode-line-remote mode-line-window-dedicated)
                      ;;  display (min-width (6.0)))
                      mode-line-frame-identification mode-line-buffer-identification "   "
                      ;; mode-line-position
                      (project-mode-line project-mode-line-format)
                      (vc-mode vc-mode) "   " mode-line-modes mode-line-misc-info
                      mode-line-end-spaces)))



;;; which key
(use-package which-key
  :init
  (setopt which-key-sort-order #'which-key-key-order-alpha
          which-key-sort-uppercase-first nil
          which-key-add-column-padding 1
          which-key-max-display-columns nil
          which-key-min-display-lines 6
          which-key-side-window-slot -10
          which-key-max-description-length nil
          which-key-idle-delay 0.5
          which-key-separator ":"
          which-key-allow-multiple-replacements t
          which-key-popup-type 'minibuffer
          )
  (which-key-mode) 
  )
;;; calc


(use-package casual-suite
  :ensure t
  :general
  ('normal calc-mode-map
           "?" 'casual-calc-tmenu))

;;; file manager

(defun dired-get-size ()
  (interactive)
  (let ((files (dired-get-marked-files)))
    (with-temp-buffer
      (apply 'call-process "/usr/bin/du" nil t nil "-sch" files)
      (message "Size of all marked files: %s"
               (progn 
                 (re-search-backward "\\(^[0-9.,]+[A-Za-z]+\\).*total$")
                 (match-string 1))))))

(use-package dired
  :init
  (setopt
   dired-kill-when-opening-new-dired-buffer t)
  :general-config
  (dired-mode-map
   "C-c s" 'dired-get-size))

;;; grammar

(use-package ispell
  :hook ((prog-mode org-mode LaTeX-mode) . ispell-minor-mode)
  :init
  (setopt
   ispell-program-name "hunspell"
   ispell-dictionary "en_US")
  :config
  (ispell-set-spellchecker-params)
  (ispell-hunspell-add-multi-dic "en_US")
  :general-config
  (ispell-minor-keymap
   "C-c d" 'ispell-word
   "RET" nil
   "SPC" nil))

(use-package flyspell
  :hook ((org-mode LaTeX-mode) . flyspell-mode))
;;; shells

(use-package ghostel
  :ensure t
  :hook
  (eshell-load . ghostel-eshell-visual-command-mode)
  :general-config
  (ghostel-semi-char-mode
   "C-s" 'consult-line
   "M-p" (lambda () (interactive) (ghostel-send-key "p" "ctrl"))
   "M-n" (lambda () (interactive) (ghostel-send-key "n" "ctrl")))
  :config
  (el-patch-defun ghostel-eshell--exec-visual (&rest args)
    "Replacement for `eshell-exec-visual' that dispatches to ghostel.
ARGS are the program name followed by its arguments, as passed by
eshell."
    (require 'esh-ext)
    (require 'esh-util)
    (save-current-buffer
      (let* ((eshell-interpreter-alist nil)
             (interp (eshell-find-interpreter (car args) (cdr args)))
             (program (car interp))
             (el-patch-add (program (if (tramp-tramp-file-p default-directory)  
                                        (tramp-file-name-localname              
                                         (tramp-dissect-file-name (car interp)))
                                      (car interp))))
             (prog-args (flatten-tree
                         (eshell-stringify-list
                          (append (cdr interp) (cdr args)))))
                                        
             (buf (generate-new-buffer
                   (concat "*" (file-name-nondirectory program) "*"))))
        (switch-to-buffer buf)
        (ghostel-exec buf program prog-args)
        (with-current-buffer buf
          (setq-local ghostel-kill-buffer-on-exit
                      (bound-and-true-p eshell-destroy-buffer-when-process-dies))
          (unless ghostel-eshell-track-title
            (setq-local ghostel-buffer-name-function nil))
          (add-hook 'ghostel-exit-functions
                    #'ghostel-eshell--visual-exit nil t))
        nil)))
  )

(use-package evil-ghostel
  :ensure t
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode))

;; (use-package vterm
;;   :ensure t
;;   :hook (vterm-mode . (lambda () (setq evil-insert-state-modes nil))))

;; Bash completion for eshell.

;; Bash completion for eshell.
;; (use-package bash-completion
;;   :ensure t)

;; (defun my-eshell-bash-completion-capf-nonexclusive ()
;;   "Bash completion function for `completion-at-point-functions'.

;; Returns the same list as the one returned by
;; `bash-completion-dynamic-complete-nocomint' appended with
;; \(:exclusive no) so that other completion functions are tried
;; when bash-completion fails to match the text at point."
;;   (let* ((bol-pos (save-mark-and-excursion
;;                     (eshell-bol)
;;                     (point)))
;;          (compl (bash-completion-dynamic-complete-nocomint
;;                  bol-pos
;;                  (point) t)))
;;     (when compl
;;       (append compl '(:exclusive no)))))

;; (use-package eat
;;   :ensure t
;;   :config
;;   (el-patch-defun eat--eshell-exec-visual (&rest args)
;;     "Run the specified PROGRAM in a terminal emulation buffer.

;; ARGS are passed to the program.  At the moment, no piping of input is
;; allowed."
;;     (require 'esh-ext)
;;     (require 'esh-util)
;;     (let* ((eshell-interpreter-alist nil)
;;            (interp (eshell-find-interpreter (car args) (cdr args)))
;;            (program (car interp))
;;            (el-patch-add (program (if (tramp-tramp-file-p default-directory)
;;                                       (tramp-file-name-localname
;;                                        (tramp-dissect-file-name (car interp)))
;;                                     (car interp))))
;;            (args (flatten-tree
;;                   (eshell-stringify-list (append (cdr interp)
;;                                                  (cdr args)))))
;;            (eat-buf
;;             (generate-new-buffer
;;              (concat "*" (file-name-nondirectory program) "*")))
;;            (eshell-buf (current-buffer)))
;;       (with-current-buffer eat-buf
;;         (switch-to-buffer eat-buf)
;;         (eat-mode)
;;         (setq-local eshell-parent-buffer eshell-buf)
;;         (setq-local eat-kill-buffer-on-exit nil)
;;         (eat-exec eat-buf program program nil args)
;;         (let ((proc (get-buffer-process eat-buf)))
;;           (if (and proc (eq 'run (process-status proc)))
;;               (let ((sentinel (process-sentinel proc)))
;;                 (add-function  :after (var sentinel)
;;                                #'eat--eshell-visual-sentinel)
;;                 (set-process-sentinel proc sentinel))
;;             (error "Failed to invoke visual command")))
;;         (eat-semi-char-mode)))
;;     nil)
;;   :hook
;;   (eshell-mode . eat-eshell-visual-command-mode)
;;   )

(use-package eshell
  :hook ((eshell-first-time-mode . (lambda () (yas-minor-mode -1)))
         ((eshell-mode shell-mode) . (lambda () (corfu-mode -1)))
         ;; (eshell-mode . (lambda () (setq completion-at-point-functions (cape-capf-super (cape-capf-nonexclusive #'pcomplete-completions-at-point) #'my-eshell-bash-completion-capf-nonexclusive)))))
         )
  :init
  (setopt
   password-cache-expiry 3600
   eshell-prefer-lisp-functions t
   ;; password-cache 5
   password-cache-expiry 3600
   eshell-modules-list '(eshell-alias eshell-banner eshell-basic eshell-cmpl eshell-dirs
                                      eshell-extpipe eshell-glob eshell-hist eshell-ls
                                      eshell-pred eshell-prompt eshell-script eshell-term
                                      eshell-unix ;; eshell-elecslash
                                      )
   eshell-visual-commands '("vi" "vim" "nvim" "screen" "tmux" "top" "htop" "less" "more" "lynx"
                            "links" "ncftp" "ncmpcpp" "mutt" "pine" "tin" "trn" "elm" "virsh"))
  :config
  (require 'em-tramp)
  (advice-add #'pcomplete-completions-at-point :around (lambda (orig-fun &rest args) (apply (cape-capf-nonexclusive orig-fun) args)))
  :general-config
  ('(normal insert) eshell-hist-mode-map
   "M-r" 'cape-history))

;;; embark


(use-package embark
  :ensure t
  :general
  ('(insert normal hybrid motion visual operator)
   "C-." 'embark-act
   "C-;" 'embark-dwim)
  (help-map
   ;; ("C-." . embark-act)         ;; pick some comfortable binding
   ;; ("C-;" . embark-dwim)        ;; good alternative: M-.
   "B" 'embark-bindings) ;; alternative for `describe-bindings'

  :init

  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  ;; Show the Embark target at point via Eldoc. You may adjust the
  ;; Eldoc strategy, if you want to see the documentation from
  ;; multiple providers. Beware that using this can be a little
  ;; jarring since the message shown in the minibuffer can be more
  ;; than one line, causing the modeline to move up and down:

  ;; (add-hook 'eldoc-documentation-functions #'embark-eldoc-first-target)
  ;; (setq eldoc-documentation-strategy #'eldoc-documentation-compose-eagerly)

  ;; Add Embark to the mouse context menu. Also enable `context-menu-mode'.
  ;; (context-menu-mode 1)
  ;; (add-hook 'context-menu-functions #'embark-context-menu 100)

  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; Consult users will also want the embark-consult package.

(use-package embark-consult
  :ensure t)
;;; emacs
(defun my-ctrl-g ()
  (interactive)
  (if (minibufferp)
      (abort-recursive-edit)
    (keyboard-quit)))



(use-package emacs
  :hook
  ((Info-mode prog-mode evil-org-mode html-ts-mode ibuffer-mode imenu-list-minor-mode dired-mode LaTeX-mode devdocs-mode yaml-mode) . (lambda () (setq display-line-numbers 'visual)))
  ((prog-mode LaTeX-mode fundamental-mode org-mode) . electric-pair-local-mode)
  :mode ("init.el" . (lambda () (emacs-lisp-mode) (outline-minor-mode 1) (evil-close-folds)))
  :general-config
  ('(normal insert) 
   "C-g" 'my-ctrl-g)
  :config
  (setopt
   use-short-answers t
   undo-limit 400000
   undo-strong-limit 3000000
   undo-outer-limit 48000000
   native-comp-async-report-warnings-error nil
   backup-directory-alist `(("." . ,(concat user-emacs-directory "backups/")))
   indent-tabs-mode nil ;; treat tabs as spaces
   x-stretch-cursor t
   window-combination-resize t
   sentence-end-double-space nil
   doc-view-resolution 200
   enable-recursive-minibuffers t
   read-extended-command-predicate #'command-completion-default-include-p
   minibuffer-prompt-properties
   '(read-only t cursor-intangible t face minibuffer-prompt)
   auto-save-visited-interval 1
   inhibit-splash-screen 1
   shift-select-mode nil
   async-shell-command-buffer 'rename-buffer
   blink-matching-paren nil
   bidi-inhibit-bpa t
   redisplay-skip-fontification-on-input t
   highlight-nonselected-windows nil
   inhibit-message-regexps '("No highlights or annotations found for" "Saving file" "Wrote" "Quit" "Undo" "Using try-expand-dabbrev" "Quit" "Mark saved where search started")
   mode-line-percent-position nil)
  (setq-default
   truncate-lines t
   bidi-display-reordering 'left-to-right
   bidi-paragraph-direction 'left-to-right
   cursor-in-non-selected-windows nil)
  (scroll-bar-mode -1)
  (auto-save-visited-mode 1)
  (winner-mode 1)
  (global-auto-revert-mode 1)
  (savehist-mode 1)
  (save-place-mode 1)
  (advice-add 'save-place-find-file-hook :after
              (lambda (&rest _)
                (when buffer-file-name (ignore-errors (recenter)))))

  (with-eval-after-load 'mule-util
    (setq
     truncate-string-ellipsis "..."))
  (load-theme 'modus-vivendi t)
  (blink-cursor-mode 0)
  (put 'list-timers 'disabled nil))


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(bmkp-last-as-first-bookmark-file "/home/alal/.emacs.d/bookmarks")
 '(custom-safe-themes
   '("b243ec44629b75034c83be3fa411662f89582223012e8f4110a82dc40bf8561a"
     "57496b1da377e22301a964a691534c6f782642c8df57453c2971685c6de08ba1"
     "530e730924892af285af79d88339048da48c572a3c974882682eadb9881fb051"
     default))
 '(safe-local-variable-values
   '((eval unless (string-search "Sun" (current-time-string))
           (my-create-annoying-timer "8:00pm")
           (my-create-annoying-timer "6:30pm")
           (my-create-annoying-timer "2:30pm")
           (my-create-annoying-timer "12:00pm")
           (my-create-annoying-timer "8:30am")))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-habit-alert-face ((t (:background "#2dc937" :foreground "black"))))
 '(org-habit-alert-future-face ((t (:background "#2dc937" :foreground "black"))))
 '(org-habit-clear-face ((t (:background "#e7b416" :foreground "black"))))
 '(org-habit-clear-future-face ((t (:background "#e7b416" :foreground "black"))))
 '(org-habit-overdue-face ((t (:background "#cc3232" :foreground "black"))))
 '(org-habit-overdue-future-face ((t (:background "#cc3232" :foreground "black"))))
 '(org-habit-ready-face ((t (:background "#2dc937" :foreground "black"))))
 '(org-habit-ready-future-face ((t (:background "#2dc937" :foreground "black")))))
(put 'narrow-to-region 'disabled nil)
(put 'narrow-to-page 'disabled nil)
