(require 'ert)

(defun fsharp-mode-wrapper (bufs body)
  "Load fsharp-mode and make sure any completion process is killed after test"
  (unwind-protect
      (progn (load-fsharp-mode)
             (funcall body))
    (ac-fsharp-quit-completion-process)
    (dolist (buf bufs)
      (when (get-buffer buf)
        (switch-to-buffer buf)
        (revert-buffer t t)
        (kill-buffer buf)))
    ;(when (get-buffer "*fsharp-complete*")
    ;  (kill-buffer "*fsharp-complete*"))
    ))

(ert-deftest start-completion-process ()
  "Check that we can start the completion process and request help"
  (fsharp-mode-wrapper '("Program.fs")
   (lambda ()
     (let ((buf (find-file "Test1/Program.fs")))
       (ac-fsharp-launch-completion-process)
       (kill-buffer "Program.fs")
       (should (buffer-live-p (get-buffer "*fsharp-complete*")))
       (should (process-live-p (get-process "fsharp-complete")))
       (process-send-string "fsharp-complete" "help\n")
       (accept-process-output ac-fsharp-completion-process 1)
       (switch-to-buffer "*fsharp-complete*")
       (should (search-backward "trigger completion request" nil t))))))

(defconst waittime 1
  "Seconds to wait for data from background process")
(defconst sleeptime 1
  "Seconds to wait for data from background process")


(ert-deftest check-project-files ()
  "Check the program files are set correctly"
  (fsharp-mode-wrapper '("Program.fs")
   (lambda ()
     (find-file "Test1/Program.fs")
     (ac-fsharp-load-project "Test1.fsproj")
     (accept-process-output ac-fsharp-completion-process waittime)
     (while (eq nil ac-fsharp-project-files)
       (sleep-for 1))
     (should (string-match-p "Test1/Program.fs" (mapconcat 'identity ac-fsharp-project-files "")))
     (should (string-match-p "Test1/FileTwo.fs" (mapconcat 'identity ac-fsharp-project-files ""))))))


(ert-deftest check-completion ()
  "Check completion-at-point works"
  (fsharp-mode-wrapper '("Program.fs")
   (lambda ()
     (find-file "Test1/Program.fs")
     (ac-fsharp-load-project "Test1.fsproj")
     ;(sleep-for sleeptime)
     (search-forward "X.func")
     (delete-backward-char 2)
     (completion-at-point)
     (accept-process-output ac-fsharp-completion-process waittime)
     (beginning-of-line)
     (should (search-forward "X.func")))))


(ert-deftest check-gotodefn ()
  "Check jump to definition works"
  (fsharp-mode-wrapper '("Program.fs")
   (lambda ()
     (find-file "Test1/Program.fs")
     (ac-fsharp-load-project "Test1.fsproj")
     (while (eq nil ac-fsharp-project-files)
       (sleep-for 1))
     (search-forward "X.func")
     (backward-char 2)
     ;(accept-process-output ac-fsharp-completion-process waittime)
     (shell-command "sleep 3")
     (ac-fsharp-gotodefn-at-point)
     (while (eq (point) 88)
       (sleep-for 1))
     ;(shell-command "sleep 5")
     ;(accept-process-output ac-fsharp-completion-process waittime)
     ;(sleep-for 10)
     (should (eq (point) 18)))))

(ert-deftest timetest ()
  (let ((now (cadr (current-time))))
    ;(shell-command "sleep 5")
    (sleep-for 5)
    (should (< now (- (cadr (current-time)) 3)))))

(ert-deftest simple-runthrough ()
  "Just a quick run-through of the main features"
  (fsharp-mode-wrapper
   (lambda ()
     (find-file "Test1/Program.fs")
     (ac-fsharp-load-project "Test1.fsproj")
     (accept-process-output ac-fsharp-completion-process waittime)
     (sleep-for sleeptime)
     ;(message (mapconcat 'identity ac-fsharp-project-files ""))
     (should (and (string-match-p "Test1/Program.fs" (mapconcat 'identity ac-fsharp-project-files ""))
                  (string-match-p "Test1/FileTwo.fs" (mapconcat 'identity ac-fsharp-project-files ""))))
     (search-forward "X.func")
     (backward-char 2)
     (ac-fsharp-gotodefn-at-point)
     (accept-process-output ac-fsharp-completion-process waittime)
     (sleep-for sleeptime)
     (should (eq (point) 18))
     (search-forward "X.func")
     (delete-backward-char 2)
     (completion-at-point)
     (accept-process-output ac-fsharp-completion-process waittime)
     (sleep-for sleeptime)
     (beginning-of-line)
     (should (search-forward "X.func"))
     (beginning-of-line)
     (search-forward "X.func")
     (delete-backward-char 1)
     (backward-char)
     (ac-fsharp-get-errors)
     (accept-process-output ac-fsharp-completion-process waittime)
     (sleep-for sleeptime)
     (should (eq (length (overlays-at (point))) 1))
     (should (eq (overlay-get (car (overlays-at (point))) 'face)
                 'fsharp-error-face))
     (revert-buffer t t)
     (kill-buffer "Program.fs"))))
