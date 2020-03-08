;;; arcanist-flymake.el --- An arcanist Flymake backend  -*- lexical-binding: t; -*-
(defvar-local arcanist--flymake-proc nil)

(defvar-local arcanist--parser-regex
  (rx (and line-start
	   (group-n 1 (+  (or letter ".")))
	   ":" (group-n 2 (+ numeric))
	   ":" (group-n 3 (+ letter))
	   " (" (group-n 4 (+ alphanumeric))
	   ") " (group-n 5 (+ (or alphanumeric space)))
	   eol))
  "Parses arc linter output when run in compiler mode.

The format is defined in arcanist sourcecode here:
https://secure.phabricator.com/diffusion/ARC/browse/master/src/lint/renderer/ArcanistCompilerLintRenderer.php$19

This regex should match against the following examples

myfile.py:10:warning (W123) Missing semicolon
otherfile.txt:23:autofix (AUTO321) Something else
")

(defun arcanist-flymake (report-fn &rest _args)
  ;; Not having arcanist is a serious problem which should cause
  ;; the backend to disable itself, so an error is signaled.
  ;;
  (unless (executable-find
	   "arc") (error "Cannot find arc executable"))
  ;; If a live process launched in an earlier check was found, that
  ;; process is killed.  When that process's sentinel eventually runs,
  ;; it will notice its obsoletion, since it have since reset
  ;; `arcanist-flymake-proc' to a different value
  ;;
  (when (process-live-p arcanist--flymake-proc)
    (kill-process arcanist--flymake-proc))
  
  ;; Save the current buffer, the narrowing restriction, remove any
  ;; narrowing restriction.
  ;;
  (let ((source (current-buffer)))
    (save-restriction
      (widen)
      ;; Reset the `arcanist--flymake-proc' process to a new process
      ;; calling the arcanist tool.
      ;;
      (setq
       arcanist--flymake-proc
       (make-process
	:name "arcanist-flymake" :noquery t :connection-type 'pipe
	;; Make output go to a temporary buffer.
	;;
	:buffer (generate-new-buffer " *arcanist-flymake*")
	:command '("arc" "lint" "--output" "compiler")
	:sentinel
	(lambda (proc _event)
	  ;; Check that the process has indeed exited, as it might
	  ;; be simply suspended.
	  ;;
	  (when (eq 'exit (process-status proc))
	    (unwind-protect
		;; Only proceed if `proc' is the same as
		;; `arcanist--flymake-proc', which indicates that
		;; `proc' is not an obsolete process.
		;;
		(if (with-current-buffer source (eq proc arcanist--flymake-proc))
		    (with-current-buffer (process-buffer proc)
		      (goto-char (point-min))
		      ;; Parse the output buffer for diagnostic's
		      ;; messages and locations, collect them in a list
		      ;; of objects, and call `report-fn'.
		      ;;
		      (cl-loop
		       while (search-forward-regexp
			      arcanist--parser-regex
			      nil t)
		       for msg = (match-string 5)
		       for (beg . end) = (flymake-diag-region
					  source
					  (string-to-number (match-string 2)))
		       for type = (if (string-match "^warning" (match-string 3))
				      :warning
				      :error)
		       collect (flymake-make-diagnostic source
							beg
							end
							type
							msg)
		       into diags
		       finally (funcall report-fn diags)))
		  (flymake-log :warning "Canceling obsolete check %s"
			       proc))
	      ;; Cleanup the temporary buffer used to hold the
	      ;; check's output.
	      ;;
	      (kill-buffer (process-buffer proc)))))))
      ;; Send the buffer contents to the process's stdin, followed by
      ;; an EOF.
      ;;
      (process-send-region arcanist--flymake-proc (point-min) (point-max))
      (process-send-eof arcanist--flymake-proc))))

(defun arcanist-setup-flymake-backend ()
  (add-hook 'flymake-diagnostic-functions 'arcanist-flymake nil t))

(add-hook 'arcanist-mode-hook 'arcanist-setup-flymake-backend)
