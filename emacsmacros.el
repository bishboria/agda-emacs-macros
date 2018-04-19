;; C-cxnt - new lagda template - main file in pdf
;; C-cxnm - new module         - module file for pdf
;; C-cxnb - new block of code
;; C-cxnf - yank function and goal.
;; C-cxnl - yank line of function and goal.

;; load agda first, then this file.


;; I remap a few agda commands so that reloading the file
;; happens first.

;; (defun refine () (kbd "C-c C-r"))
;; (defun load-then-goal-and-context ()
;;   (interactive)
;;   (progn
;;     (agda2-load)
;;     (agda2-goal-and-context)))

;; (global-unset-key (refine))
;; (global-set-key   (refine) 'load-then-goal-and-context)


;; elisp macros useful for literate agda work

;; Create a new lagda file
(defun agda-new-lagda-template ()
  (interactive)
  (let ((name (read-string "New file name: ")))
    (let ((modulename (generate-new-buffer-name name)))
      (let ((filename (concat modulename ".lagda")))
        (switch-to-buffer filename)
        (insert (lagda-file-string modulename))
        (forward-line -5)
        (write-file filename 'confirm)))))

(global-set-key (kbd "C-c C-x C-n C-t")    'agda-new-lagda-template)


;; Create a new lagda module
(defun agda-new-lagda-module ()
  (interactive)
  (let ((name (read-string "New module name: ")))
    (let ((modulename (generate-new-buffer-name name)))
      (let ((filename (concat modulename ".lagda")))
        (switch-to-buffer filename)
        (insert (lagda-module-string modulename))
        (forward-line -5)
        (write-file filename 'confirm)))))

(global-set-key (kbd "C-c C-x C-n C-m")    'agda-new-lagda-module)


;; Insert a new code block
(defun agda-new-code-block ()
  (interactive)
  (insert (concat (begin-code-block)
                  (end-code-block)))
  (forward-line -2))

(global-set-key (kbd "C-c C-x C-n C-b")    'agda-new-code-block)


;; Yank code and goal above current code block
;;   based on current pointer position
;;   copy the code at point
;;   copy the goal state
(defun agda-yank-function-and-goal ()
  (interactive)
  (save-excursion
    (setq function-string (add-indentation (agda-copy-current-function)))
    (setq goal-string     (add-indentation (agda-get-contents-of-goal-buffer)))

    (search-backward "\\begin{code}")
    (forward-line -1)
    (insert (concat (hidden-module-definition)
                    (begin-code-block)
                    function-string
                    (end-code-block)
                    (begin-verbatim-block)
                    goal-string
                    (end-verbatim-block)))))

(global-set-key (kbd "C-c C-x C-n C-f")    'agda-yank-function-and-goal)


;; Yank the current line of a function and its goal type
(defun agda-explain-line-of-function ()
  (interactive)

  (let     ((L        (agda-copy-line))
            (G        (agda-get-contents-of-goal-buffer))
            (A        (agda-copy-para-above-point))
            (B        (agda-copy-para-below-point)))
    (let   ((hide-A   (concat (hidden-module-definition)
                              (hide-stuff (concat (begin-code-block)
                                                  (add-indentation A)
                                                  (end-code-block)))))
            (hide-B   (hide-stuff (concat (begin-code-block)
                                          (add-indentation B)
                                          (end-code-block)))))

      (let ((show-CL  (concat (begin-code-block)
                              (add-indentation L)
                              (end-code-block)
                              (begin-verbatim-block)
                              (add-indentation G)
                              (end-verbatim-block))))
        (search-backward "\\begin{code}")
        (forward-line -1)
        (insert (concat hide-A
                        show-CL
                        hide-B
                        "\n\n\n"))))))

(global-set-key (kbd "C-c C-x C-n C-l")    'agda-explain-line-of-function)


(defun agda-insert-lemma ()
  (interactive)
  (let     ((A        "-- hypothesis goes here")
            (B        "-- implementation goes here"))
    (let   ((show-A   (concat (hidden-module-definition)
                              (concat (begin-code-block)
                                      (add-indentation A)
                                      (end-code-block))))
            (hide-B   (hide-stuff (concat (begin-code-block)
                                          (add-indentation B)
                                          (end-code-block)))))
        (insert (concat "Introductory lemma text\n"
                        show-A
                        hide-B)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; The Sausage Factory
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun begin-code-block () "\n\\begin{code}\n")
(defun end-code-block   () "\n\\end{code}\n")
(defun begin-verbatim-block () "\n\\begin{verbatim}\n")
(defun end-verbatim-block () "\n\\end{verbatim}\n")

(defun hide-stuff (str)
  (concat "\n\\iffalse"
          str
          "\\fi\n"))

(defun agda-copy-line ()
  (interactive)
  (buffer-substring-no-properties (line-beginning-position)
                                  (line-end-position)))

(defun agda-copy-para-below-point ()
  (interactive)
  (save-excursion
    (forward-line)
    (set-mark (point))
    (search-forward "\\end{code}")
    (forward-line -1)
    (end-of-line)
    (buffer-substring-no-properties (region-beginning) (region-end))))

(defun agda-copy-para-above-point ()
  (interactive)
  (save-excursion
    (beginning-of-line)
    (set-mark (point))
    (search-backward "\\begin{code}")
    (forward-line)
    (buffer-substring-no-properties (region-beginning) (region-end))))

(defun agda-copy-current-function ()
  (interactive)
  (mark-paragraph)
  (buffer-substring (region-beginning) (region-end)))

(defun agda-get-contents-of-goal-buffer ()
  (interactive)
  (with-current-buffer
      (get-buffer "*Agda information*")
    (mark-whole-buffer)
    (buffer-substring-no-properties (region-beginning) (region-end))))

(defun add-indentation (str)
  (interactive)
  (mapconcat (lambda (l) (concat "  " l)) (split-string str "\n") "\n"))

(defun lagda-file-string (modulename)
  (interactive)
  (concat "\\documentclass{article}\n"
          "\\usepackage[conor]{agda}\n"
          "\\usepackage{amsmath}\n"
          "\\usepackage{upgreek}\n\n"
          "\\begin{document}\n"
          "\\title{Title}\n"
          "\\author{Author}\n"
          "\\maketitle\n\n"
          (main-module-definition modulename)
          "\\section{Introduction}\n\n\n\n\n"
          "\\bibliographystyle{plain}\n"
          "\\bibliography{Ornament}\n"
          "\\end{document}"))

(defun lagda-module-string (modulename)
  (interactive)
  (concat "\\section{"
          modulename
          "}\n"
          "\\label{sec:"
          modulename
          "}\n"
          (main-module-definition modulename)
          "\n\n\n"))


(defun main-module-definition (name)
  (interactive)
  (hide-stuff (concat (begin-code-block)
                      "module "
                      name
                      " where"
                      (end-code-block))))


;; Prefix hidden modules with the current module name
;; so it doesn't clash with other hidden modules
;; that get imported...
(defun hidden-module-definition ()
  (interactive)
  (current-progress)                     ;;; see below for current-progress
  (hide-stuff (concat (begin-code-block)
                      "module "
                      (main-module-name)
                      "-progress"
                      (number-to-string progress)
                      " where"
                      (end-code-block))))



;; Since lagda filenames and module names coincide, get rid of ".lagda" to
;; have the module name.
(defun main-module-name ()
  (interactive)
  (substring (buffer-name) 0 -6))

;; find how much progress we've made so far
;; progress value should be one higher than the number of module ...-progressX
;; found in the buffer
(defun current-progress ()
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (setq progress (1+ (how-many "progress[[:digit:]]+")))))
