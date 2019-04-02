;;; -*- encoding: sjis; Mode: Lisp; Package: EDITOR-*-
;;;
;;; This file is not part of xyzzy.
;;;
;
; eb.l
;
; Author: deecay
;
; Date: 2009 Feb   15  version 0.5
; Date: 2007 July  31  version 0.4
; Date: 2007 July  11  version 0.3
; Date: 2007 June  04  version 0.2
; Date: 2007 April 07  version 0.1
;
;   イントロダクション　http://www.geocities.jp/megahurtz_dk/eb/index.html
;   マニュアル　http://www.geocities.jp/megahurtz_dk/eb/manual.html
;
;
;
; ■ EPWING辞書ライブラリ
;
;   EPWING形式の辞書を読めるようにするライブラリ＋関数。
;
;
;   EB Library
;    http://www.sra.co.jp/people/m-kasahr/eb/index.html
;
; ■ 動作環境
;
;  xyzzy-0.2.2.225以降
;  eb.dll 4.2.2 (上記のサイトからダウンロード)
;
; ■ インストール
;
;  1. netinstallerからインストールしていない場合はこのeb.lをsite-lisp に置いて
;     バイトコンパイルします。
;  2. netinstallerのautoloadを有効にしてない場合は.xyzzyに
;
;    (require "eb")
;
;     と書きます。
;  3. 上のEB Libraryのサイトから"eb library 4.2.2 Windows インストーラ"をダウンロード。
;     展開して、中のeb.dllをxyzzy/etcフォルダに置いてください。
;  4. EPWING辞書を用意します。CATALOGファイルがあるフォルダが辞書フォルダです。
;  5. EPWING辞書の辞書フォルダを指定します。.xyzzyに以下のように書きます。
;
;    (setq *ebdict-directories* '("d:/readers" "d:/広辞苑"))
;
;
; ■ 動かし方
;
;   M-x ebdict-lookup [C-M-,]
;      セレクションか、ポイントがある単語を*ebdict-directories*の
;      最初の辞書から先頭一致で検索します。
;      C-u をつけるとミニバッファから入力した単語を検索します。
;
;   M-x ebdict-lookup-across [C-M-.]
;      セレクションか、ポイントがある単語を*ebdict-directories*の
;      全ての辞書から横断的に先頭一致で検索します。
;      C-u をつけるとミニバッファから入力した単語を検索します。
;
;   M-x ebdict-lookup-menu [C-M-/]
;      セレクションか、ポイントがある単語を検索する辞書を選ぶメニューを
;      表示します。一番上には検索する単語(総ヒット数)、そして
;      *ebdict-directories*の各辞書の名前とヒット数が続きます。
;      単語部分を選択すると横断的な(串刺し)検索に、辞書名をクリックすれば
;      その辞書で検索します。
;      C-u をつけるとミニバッファから入力した単語を検索します。
;
;
;   ebdict結果表示バッファ
;
;     RET  再検索   前回検索した辞書でポイントがある単語を再検索します。
;     @    辞書切り替え   同じ単語の デフォルト辞書<->全部 を切り替えます。
;     q    ebdict出力バッファを閉じます。
;     TAB  次の定義に進みます。
;     l    ミニバッファから入力した単語を、前回検索した辞書(単体-全体)と
;          同じ辞書タイプで再検索します。
;     L    ミニバッファから入力した単語を、前回検索した辞書(単体-全体)と
;          逆の辞書タイプで再検索します。
;     m    検索方法切り替えメニュー
;
; ■ おかしいところ
;
;   1. 複合検索ができない
;   2. 画像が表示できない
;   3. 音声を再生できない
;   4. リンクでジャンプできない
;   5. 外字は表示できない
;   6. 突然xyzzy本体を巻き込んで落ちることがある。
;   7. ほかにも色々とおかしいはず。

(provide "eb")

(in-package "editor")

(export '(*ebdict-directories* *ebdict-use-ilookup* *ebdict-max-hits*
		  *ebdict-split-vertically* *ebdict-heading-attribute*
		  *ebdict-color-query-in-result* *ebdict-query-attribute*
		  *ebdict-dictionary-title-format* *ebdict-dictionary-title-attribute*
		  *ebdict-record-history* *ebdict-history-file* *ebdict-history-file*
		  *ebdict-output-mode-map* *ebdict-mode-map*
		  *ebdict-keywords-regexp* *ebdict-use-aspell* *eb-aspell-path*
		  *eb-aspell-dll-file* *eb-aspell-lang*))

(export '(ebdict-lookup-menu ebdict-lookup ebdict-lookup-across
		  ebdict-mode))

(defvar *ebdict-directories* nil
  "List of EPWING dictionary paths.")

(defvar *ebdict-use-ilookup* nil
  "If t, lookup incrementally for single dictionary lookup.")

(defvar *ebdict-max-hits* 20
  "Maximum nuber of hits per dictionary.")

(defvar *ebdict-split-vertically* nil
  "Split screen vertically (side-by-side) if t.")

(defvar *ebdict-show-in-popup* nil
  "Show result in popup if t. Otherwise use buffer as output.")

(defvar *ebdict-heading-attribute* '(:foreground 6 :bold t)
  "See set-text-attribute in reference for format.")

;(defvar *ebdict-number-attribute* '(:color nil nil :bold)
;	"See regexp-keyword-list for format.")

(defvar *ebdict-color-query-in-result* t
  "Colorize search query in result output.")

(defvar *ebdict-query-attribute* '(:color 2)
  "Color attribute used for query highlighting if
*ebdict-color-query-in-result* is set to t")

(defvar *ebdict-dictionary-title-format* "######"
  "String used in output to indicate dictionary title.")

(defvar *ebdict-dictionary-title-attribute* '(:color 2)
  "Color attribute for dictionary title in output buffer.")

(defvar *ebdict-record-history* nil
  "If t, save search history to file *ebdict-history-file*.")

(defvar *ebdict-history-file* "~/eb.history"
  "File path for search history.")

(defvar *ebdict-use-aspell* nil
  "Use aspell to suggest alternate spelling when no entries were found.")

(defvar *ebdict-skip-no-hits* nil
  "Skip dictionaries with zero hits when t.")



(defvar *ebdict-syntax-table* nil)
(unless *ebdict-syntax-table*
  (setq *ebdict-syntax-table* (make-syntax-table))
  (set-syntax-start-comment *ebdict-syntax-table* #\[)
  (set-syntax-end-comment *ebdict-syntax-table* #\]))

(defvar *ebdict-output-mode-map* nil)
(unless *ebdict-output-mode-map*
  (setq *ebdict-output-mode-map* (make-sparse-keymap))
  (define-key *ebdict-output-mode-map* #\q 'ebdict-output-quit)
  (define-key *ebdict-output-mode-map* #\m 'ebdict-change-method)
  (define-key *ebdict-output-mode-map* #\M 'ebdict-output-change-dictionary)
  (define-key *ebdict-output-mode-map* #\TAB 'ebdict-output-next-definition)
  (define-key *ebdict-output-mode-map* #\n 'ebdict-output-next-definition)
  (define-key *ebdict-output-mode-map* #\p 'ebdict-output-previous-definition)
  (define-key *ebdict-output-mode-map* #\N 'ebdict-output-next-dictionary)
  (define-key *ebdict-output-mode-map* #\P 'ebdict-output-previous-dictionary)
  (define-key *ebdict-output-mode-map* #\l 'ebdict-output-prompt)
  (define-key *ebdict-output-mode-map* #\L 'ebdict-output-prompt-opposite)
  (define-key *ebdict-output-mode-map* #\RET 'ebdict-output-return)
  (define-key *ebdict-output-mode-map* #\C-h 'ebdict-output-prev-page)
  (define-key *ebdict-output-mode-map* #\@ 'ebdict-output-toggle-single-across)
  (define-key *ebdict-output-mode-map* #\= 'ebdict-output-show-current-heading)
  (define-key *ebdict-output-mode-map* #\/ 'ebdict-output-menu))


(defvar *ebdict-buf-name* " *ebdict*")

(defvar *ebdict-last-single-dictionary* nil
  "For internal use. Holds last dictionary path for single search.")

(defvar *ebdict-last-query* nil
  "For internal use. Holds last search history.")

(defvar *ebdict-method* nil
  "For internal use. Seach method
'forward
'backward
'exact
'cross
'keyword")

(defun ebdict-lookup-menu (&optional word)
  "Show dictionary selection menu."
  (interactive)
  (when *prefix-args*
	(setq word (read-string "Lookup(menu): " :default *ebdict-last-query*)))
  (let* ((word (or word (ebdict-get-word)))
		 (match-pairlist (ebdict-get-matches word)))
	(setq total (ebdict-get-total-maches match-pairlist))
	(setq m (create-popup-menu))
	(add-menu-item m 'term (format nil "~A (~d)" word total)
				   #'(lambda () (interactive)
					   (setq *prefix-args* nil)
					   (ebdict-lookup-across word)))
	(add-menu-separator m)
	(dolist (match match-pairlist)
	  (let ((dic-file-path (car match))
			(match-count (cdr match)))
		(setq dic-name (file-namestring (remove-trail-slash dic-file-path)))
		(add-menu-item m
					   (make-symbol dic-name)
					   (format nil "~A (~s)" dic-name match-count)
					   #'(lambda () (interactive)
						   (setq *prefix-args* nil)
						   (ebdict-lookup-1 word dic-file-path))))))
  (track-popup-menu m))

(defun ebdict-get-matches (word)
  "Get match count of WORD for all dictionaries.
Retruns '((dic-file-path . match-count) (dic-file-path . match-count) ..)
match-count might be string \"E\" when an error occured during lookup."
  (let ((dic-list (reverse (ebdict-get-paths)))
		result-alist)
	(dolist (dic-file-path dic-list)
	  (when (eb-epwing-directory-p dic-file-path)
		(setq eb-output (eb-count-hits word dic-file-path :method *ebdict-method* :max *ebdict-max-hits*))
		(setq match-count (if (ebdict-success eb-output)
							  (cdr eb-output)
							"E"))
		(push (cons dic-file-path match-count) result-alist)))
	(ebdict-sort-matches-by-count result-alist)))

(defun ebdict-success (output)
  (zerop (car output)))

(defun ebdict-sort-matches-by-count (result)
  (sort result #'(lambda (x y) (and (numberp y) (zerop y))) :key #'cdr))

(defun ebdict-get-total-maches (result)
  (apply #'+ (mapcar #'(lambda (x) (if (numberp x) x 0)) (mapcar #'cdr result))))


(defvar *ebdict-path-error-string* (concat "No path specified. \n"
										   "Please set *ebdict-directories*."))


(defun ebdict-lookup (&optional word path)
  "Lookup word in PATH or default (first) dictionary."
  (interactive)
  (if word
	  (ebdict-lookup-1 word path)
	(if *prefix-args*
		(if *ebdict-use-ilookup*
			(ebdict-ilookup path)
		  (ebdict-lookup-1 (ebdict-read-word path) path))
	  (progn
		(setq word (ebdict-get-word))
		(if word
			(ebdict-lookup-1 word path)
		  (if *ebdict-use-ilookup*
			  (ebdict-ilookup path)
			(ebdict-lookup-1 (ebdict-read-word path) path)))))))


(defun ebdict-lookup-1 (&optional word path)
  (let* ((word (or word (ebdict-get-word)))
		 (path (or path (car (ebdict-get-paths)))))
	(when (not path)
	  (message-box *ebdict-path-error-string*)
	  (return-from ebdict-lookup-1 nil))
	(setq eb-output (eb-lookup word path
							   :method *ebdict-method*
							   :max *ebdict-max-hits*))
	(when (not (ebdict-success eb-output))
	  (message (cdr eb-output))
	  (return-from ebdict-lookup-1 nil))
	(when (string/= word *ebdict-last-query*)
	  (ebdict-record-history word))
	(setq *ebdict-last-query* word)
	(if *ebdict-show-in-popup*
		(ebdict-show-in-popup eb-output path)
	  (ebdict-show eb-output path))
	(message "ebdict looking for \"~A\" in ~A" word (string-upcase path))))

(defun ebdict-read-word (&optional path)
  (let* ((prompt-string (format nil "Lookup(~A): "
								(ebdict-get-dname (or path (car (ebdict-get-paths)))))))
	(read-string prompt-string :default *ebdict-last-query*)))

(defun ebdict-ilookup (&optional path)
  "Incremental lookup in dictionary."
  (interactive)
  (let ((input "")
		(*ebdict-record-history* nil)
		(dname (ebdict-get-dname (or path
									 (get-buffer-alternate-file-name)
									 (car (ebdict-get-paths))))))
	;; do not record every change in history file for iLookup
	(declare (special *ebdict-record-history*))
	(loop
	  (minibuffer-prompt (format nil "iLookup(~A): ~A" dname input))
	  (let ((c (read-char *keyboard*)))
		(case c
		  ((#\RET #\C-i)
		   (ebdict-record-history input t)
		   (push input *minibuffer-default-history*)
		   (return-from ebdict-ilookup nil))
		  (#\C-g
		   (quit))
		  (#\C-h (or (zerop (length input))
					 (setq input (substring input 0 -1))))
		  (t
		   (setq input (format nil "~A~A" input c))
		   (ebdict-lookup-1 input path)))))))

(defun ebdict-lookup-across (&optional word dictionaries)
  (interactive)
  (when (or *prefix-args*
			(and (not word) (not (ebdict-get-word))))
	(setq word (read-string "Lookup(across): " :default *ebdict-last-query*)))
  (let ((word (or word (ebdict-get-word)))
		(paths (or dictionaries (ebdict-get-paths)))
		success)
	(when word
	  (when (find-buffer *ebdict-buf-name*)
		(ebdict-delete-buffer-contents *ebdict-buf-name*))
	  (when (string/= word *ebdict-last-query*)
		(ebdict-record-history word))
	  (setq *ebdict-last-query* word)
	  (dolist (path (reverse (ebdict-get-paths)))
		(setq success
			  (or (ebdict-show (eb-lookup word path :method *ebdict-method* :max *ebdict-max-hits*) path t)
				  success)))
	  (ebdict-buffer-undo-boundary *ebdict-buf-name*)
	  (unless success
		(message "ebdict error lookup-across")
		(return-from ebdict-lookup-across nil))
	  (message "ebdict looking for \"~A\" in multiple dictionaries." word))))

(defun ebdict-lookup-regexp (&optional word path)
  (interactive)
  (when *prefix-args*
	(setq word (read-string "Lookup(full): " :default *ebdict-last-query*)))
  (let ((word (or word (ebdict-get-word) (ebdict-read-word))))
	(when word
	  (setq *ebdict-last-query* word)
	  (long-operation
		(ebdict-enumerate #'(lambda (heading text) (or (string-match (compile-regexp word t) text)))
						  path)))))

(defun ebdict-lookup-clipboard ()
  (interactive)
  (let ((word (get-clipboard-data)))
	(when (stringp word)
	  (ebdict-lookup-1 word))))

(defun ebdict-lookup-across-clipboard ()
  (interactive)
  (let ((word (get-clipboard-data)))
	(when (stringp word)
	  (ebdict-lookup-across word))))


(defun ebdict-enumerate (fn &optional path)
  (let ((path (or path (car (ebdict-get-paths)))))
	(when (not path)
	  (message-box *ebdict-path-error-string*)
	  (return-from ebdict-enumerate nil))
	(when (not (functionp fn))
	  (message-box "First argument must be function")
	  (return-from ebdict-enumerate nil))
	(ebdict-show (cons 0 (eb-enumerate fn path)) path)))

(defun ebdict-show (eb-output dictionary-path &optional across)
  "Show definition in buffer."
  (when (ebdict-success eb-output)
	(let ((result-list (cdr eb-output))
		  (c (selected-buffer))
		  (b (get-buffer-create *ebdict-buf-name*)))
	  (save-excursion
		(set-buffer b)
		(ebdict-output-mode)
		(setq buffer-read-only nil)
		(ebdict-insert-title result-list dictionary-path across)
		(ebdict-insert-result result-list)
		(goto-char (point-min))
		(run-hooks (ebdict-get-hook dictionary-path))
		(setq buffer-read-only t)
		(update-mode-line)
		(when *ebdict-color-query-in-result*
		  (ebdict-color-query))
		(goto-char (point-min)))
	  (when (and (eq (count-windows) 1) (not (get-buffer-window b)))
		(split-window nil *ebdict-split-vertically*))
	  ;(user::m "~A:~A" (get-buffer-window b) (equal b c))
	  (if (get-buffer-window b)
		  (if (equal b c)
			  (switch-to-buffer b)
			(pop-to-buffer b)))
	  (if (and (not (get-buffer-window b))
			   (not (equal b c)))
		  (pop-to-buffer b t)))
	t))

(defun ebdict-insert-title (result path continue)
  (cond
   (continue
	(unless (and *ebdict-skip-no-hits*
				 (zerop (length result)))
	  (setq pt (point))
	  (insert (format nil "~A ~A (~A)"
					  *ebdict-dictionary-title-format* (ebdict-get-dname path) (length result)))
	  (save-excursion (set-text-attribute pt (progn (goto-eol) (point)) 'title))
	  (insert "\n\n")
	  (set-buffer-alternate-file-name nil)))
   ;normal lookup
   (t
	(delete-region (point-min) (point-max))
	(set-buffer-alternate-file-name (truename path))
	(setq *ebdict-last-single-dictionary* (truename path))
	; aspell using aspell dll.
	(when (not result)
	  (insert (format nil "No results in ~A\n\n" (ebdict-get-dname path)))
	  (when *ebdict-use-aspell*
		(ebdict-insert-aspell path))))))

(defun ebdict-insert-aspell (path)
  (let* ((aspell-result (ebdict-aspell *ebdict-last-query*))
		 (aspell-error (string-looking-at "Aspell error:" (or (car aspell-result) ""))))
	(insert (format nil "Alternate spelling in ~A (~A):\n"
					*eb-aspell-lang*
					(if aspell-error 0 (length aspell-result))))
	(setq p-heading (point))
	(insert (aspell-convert-encoding
			 (format nil "~{~A\n~}" aspell-result)))
	(apply #'set-text-attribute p-heading (point) 'heading
		   *ebdict-heading-attribute*)))

(defun ebdict-insert-result (result)
  (dolist (def result)
	(setq heading (car def))
	(setq text (cdr def))
	(when (and (> (length text) (length heading))
			   (string= (substring text 0 (length heading)) heading))
	  (setq text (substring text (length heading))))
	(setq p-heading (point))
	(insert heading "  ")
	(apply #'set-text-attribute p-heading (point) 'heading
		   *ebdict-heading-attribute*)
	(setq p-honbun (point))
	(insert text "\n")
	(set-text-attribute p-honbun (point) 'text
						:foreground 0)))

(defun ebdict-insert-result-more ()
  (goto-char (point-max))
  (when (get-buffer-alternate-file-name)
	(let ((shown-result-count (ebdict-get-shown-result-count)))
	  (save-window-excursion
		(save-excursion
		  (setq buffer-read-only nil)
		  (ebdict-insert-result (cdr (eb-lookup *ebdict-last-query* (get-buffer-alternate-file-name) :max *ebdict-max-hits* :from shown-result-count)))
		  (setq buffer-read-only t))))))

(defun ebdict-get-shown-result-count ()
  (save-window-excursion
	(save-excursion
	  (goto-char (point-max))
	  (let ((count 0))
		(while (ebdict-output-previous-definition)
		  (setq count (1+ count)))
		count))))

(defun ebdict-show-in-popup (output path)
  (popup-string (with-output-to-string (so)
				  (dolist (x (cdr output))
					(format so "~A\n~A\n" (car x) (cdr x))))
				(point)))

(defun use-regexp-keyword-list (&rest rekwd-lists)
  "与えられた compile 済み regexp-keyword-list 全てを現在のバッファに適用する。"
  (when (or (local-variable-p 'regexp-keyword-list)
            (make-local-variable 'regexp-keyword-list))
    (setq regexp-keyword-list
          (apply 'append regexp-keyword-list rekwd-lists))))

(defun ebdict-color-query (&optional word)
  (setq word (or word *ebdict-last-query*))
  (use-regexp-keyword-list (compile-regexp-keyword-list
							 `((,word t ,*ebdict-query-attribute* nil)))))

(defun ebdict-delete-buffer-contents (buffer)
  (save-excursion
	(set-buffer (find-buffer buffer))
	(setq buffer-read-only nil)
	(delete-region (point-min) (point-max))
	(setq buffer-read-only t)))

(defun ebdict-buffer-undo-boundary (buffer)
  (save-excursion
	(set-buffer (find-buffer buffer))
	(undo-boundary)))

(defun ebdict-get-paths ()
  "Return list of dictionary searching paths.

If *ebdict-directories* is set, each item is added as a search-path.
Item can be string, or in the form of
\(path . hooks\)."
  (let (dict-paths)
	(dolist (path *ebdict-directories*)
	  (when (consp path)
		(setq path (car path)))
	  (unless (member path dict-paths :test #'path-equal)
		(push path dict-paths)))
	(reverse dict-paths)))

(defun ebdict-get-word ()
  (if (eq (get-selection-type) 2)
	  (selection-start-end (s e)
		(buffer-substring s e))
	(save-excursion
	  (setq word (buffer-substring
	   (progn
		 (or (skip-syntax-spec-backward "w")
			 (skip-syntax-spec-backward "j"))
		 (point))
	   (progn
		 (or (skip-syntax-spec-forward "w")
			 (skip-syntax-spec-forward "j"))
		 (point))))
	  (if (string= word "")
		  nil
		word))))

(defun ebdict-get-dname (path)
  (string-upcase (file-namestring (remove-trail-slash path))))

(defun ebdict-get-hook (path)
  (cdr (assoc path *ebdict-directories* :test #'string-equal)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Mouse over popup borrowed from edic.l

(defvar-local ebdict-mode nil)
(defvar *ebdict-mode-map*
  (let ((keymap (make-sparse-keymap)))
	(define-key keymap #\MouseMove 'ebdict-mouse-lookup)
	(define-key keymap #\C-MouseMove 'ebdict-mouse-lookup-conjugation)
	keymap))

(defvar *ebdict-last-range-begin* nil)
(defvar *ebdict-last-range-end* nil)

(defun ebdict-mode (&optional (arg nil sv))
  (interactive "p")
  (ed::toggle-mode 'ebdict-mode arg sv)
  (if ebdict-mode
	  (set-minor-mode-map *ebdict-mode-map*)
	(unset-minor-mode-map *ebdict-mode-map*))
  (setq *ebdict-last-range-begin* nil)
  (update-mode-line t))

(defun ebdict-mouse-lookup (&optional conjugation)
  (interactive)
  (continue-pre-selection)
  (when ebdict-mode
	(with-selected-window
	  (set-window *last-mouse-window*)
	  (save-excursion
		(goto-last-mouse-point)
		(cond ((eolp)
			   (setq *ebdict-last-range-begin* nil))
			  ((and *ebdict-last-range-begin*
					(<= *ebdict-last-range-begin* (point))
					(< (point) *ebdict-last-range-end*))
			   (continue-popup))
			  (t
			   (let* ((end (progn
							 (skip-chars-forward "A-Za-z")
							 (point)))
					  (beg (progn
							 (skip-chars-backward "A-Za-z")
							 (point)))
					  s r)
				 (setq *ebdict-last-range-begin* beg)
				 (setq *ebdict-last-range-end* end)
				 (if (= beg end)
					 (return-from ebdict-mouse-lookup nil))
				 (setq s (buffer-substring beg end))
				 (handler-case
					 (progn
					   (setq eb-output (eb-lookup s (car (ebdict-get-paths))
												  :method *ebdict-method* :max *ebdict-max-hits*))
					   (setq r (list (safe-cdadr eb-output))))
				   (error (e)
					 (ebdict-mode nil)
					 (error e)))
				 (if (or conjugation (not r))
					 (progn
					   (setq r (ebdict-analogize-conjugation-1
								s (if r (acons s r nil) nil)))
					   (if r
						   (popup-string (with-output-to-string (so)
										   (do ((x (nreverse r) (cdr x)))
											   ((null x))
											 (format so "~A:~%~%  ~{~A~^, ~}~@[~%~%~]"
													 (caar x) (cdar x) (cdr x))))
										 beg)
						 (popup-string "見つかりまへん" beg)))
				   (popup-string (format nil "~A:~%~%~{~A~^, ~}" s r) beg)))))))))

(defun ebdict-mouse-lookup-conjugation ()
  (interactive)
  (ebdict-mouse-lookup t))

(defun ebdict-analogize-conjugation-1 (string rl)
  (mapc #'(lambda (x)
			(when (string-matchp (car x) string)
			  (let* ((s (string-replace-match string (cdr x)))
					 (eb-output (eb-lookup s (car (ebdict-get-paths))
										   :method *ebdict-method* :max *ebdict-max-hits*))
					 (r (list (safe-cdadr eb-output))))
				(when r
				  (push (cons s r) rl)))))
		ed::*edict-conjugation-regexp*)
  rl)

(pushnew '(ebdict-mode . "EB") *minor-mode-alist* :key #'car)

;; end of mouse over popup borrowed from edict.l

(defun ebdict-record-history (word &optional force)
  (when (or force *ebdict-record-history*)
	(with-open-file (fp *ebdict-history-file*
						:direction :output
						:if-exists :append
						:if-does-not-exist :create)
	  (format fp "~A\n" word))))

(defun ebdict-set-forward ()
  (interactive)
  (setq *ebdict-method* nil))

(defun ebdict-set-backward ()
  (interactive)
  (setq *ebdict-method* 'backward))

(defun ebdict-set-keyword ()
  (interactive)
  (setq *ebdict-method* 'keyword))

(defun ebdict-set-cross ()
  (interactive)
  (setq *ebdict-method* 'cross))

(defun ebdict-set-exact ()
  (interactive)
  (setq *ebdict-method* 'exact))

(defun ebdict-change-method ()
  (interactive)
  (let ((m (create-popup-menu)))
	(add-menu-item m 'forward "forward"
				   #'(lambda () (interactive) (ebdict-set-forward))
				   #'(lambda () (when (eq *ebdict-method* nil) :check)))
	(add-menu-item m 'backward "backward"
				   #'(lambda () (interactive) (ebdict-set-backward))
				   #'(lambda () (when (eq *ebdict-method* 'backward) :check)))
	(add-menu-item m 'exact "exact"
				   #'(lambda () (interactive) (ebdict-set-exact))
				   #'(lambda () (when (eq *ebdict-method* 'exact) :check)))
	(add-menu-item m 'keyword "keyword"
				   #'(lambda () (interactive) (ebdict-set-keyword))
				   #'(lambda () (when (eq *ebdict-method* 'keyword) :check)))
	(add-menu-item m 'cross "cross"
				   #'(lambda () (interactive) (ebdict-set-cross))
				   #'(lambda () (when (eq *ebdict-method* 'cross) :check)))
	(track-popup-menu m)))



(defun ebdict-output-mode ()
  (kill-all-local-variables)
  (setq mode-name "eboutput")
  (setq buffer-mode 'ebdict)
  (make-local-variable 'buffer-read-only)
  (setq buffer-read-only t)
  (setq *ebdict-keywords-regexp*
		(let ((reg (format nil "^~A.*" *ebdict-dictionary-title-format*))
			  (attr *ebdict-dictionary-title-attribute*))
		  (compile-regexp-keyword-list
		   `((,reg nil ,attr)))))
  (make-local-variable 'regexp-keyword-list)
  (setq regexp-keyword-list *ebdict-keywords-regexp*)
  (use-keymap *ebdict-output-mode-map*)
  (use-syntax-table *ebdict-syntax-table*))

(defun ebdict-output-single-p ()
  "Return t if last search was a single dict search, not across"
  (when (eq buffer-mode 'ebdict)
	(and (get-buffer-alternate-file-name)
		 (eb-epwing-directory-p (get-buffer-alternate-file-name)))))

(defun ebdict-output-prompt ()
  (interactive)
  (if (ebdict-output-single-p)
	  (ebdict-output-prompt-single)
	(call-interactively 'ebdict-output-prompt-across)))

(defun ebdict-output-prompt-opposite ()
  (interactive)
  (if (ebdict-output-single-p)
	  (call-interactively 'ebdict-output-prompt-across)
	(ebdict-output-prompt-single)))

(defun ebdict-output-prompt-single ()
  "Prompt to search a word in dictionary from output buffer."
  (interactive)
  (setq *prefix-args* t)
  (ebdict-lookup nil (get-buffer-alternate-file-name)))

(defun ebdict-output-prompt-across (word)
  "Prompt to search a word in all dictionaries from output buffer."
  (interactive "sLookup(across): " :default *ebdict-last-query*)
  (when word
	(ebdict-lookup-across word)))

(defun ebdict-output-toggle-single-across ()
  (interactive)
  (if (ebdict-output-single-p)
	  (ebdict-lookup-across-again)
	(ebdict-lookup-again)))

(defun ebdict-lookup-again ()
  "Search last word again in single dictionary.

Used in toggle single-accross. Look up in previous single
dictionary. If there are no previous dictionary, use the first
one in dictionary list."
  (interactive)
  (ebdict-lookup *ebdict-last-query* *ebdict-last-single-dictionary*))

(defun ebdict-lookup-across-again ()
  "Search last word again in ALL dictionaries this time."
  (interactive)
  (ebdict-lookup-across *ebdict-last-query*))

(defun ebdict-output-return ()
  (interactive)
  (if (ebdict-output-single-p)
	  (ebdict-output-lookup)
	(ebdict-output-lookup-across)))

(defun ebdict-output-lookup ()
  "Search word under cursor in dictionary from output buffer."
  (interactive)
  (let ((word (ebdict-get-word)))
	(when word
	  (ebdict-lookup word (get-buffer-alternate-file-name)))))

(defun ebdict-output-lookup-across ()
  "Search word under cursor in ALL dictionaries from output buffer."
  (interactive)
  (let ((word (ebdict-get-word)))
	(when word
	  (ebdict-lookup-across word))))

(defun ebdict-output-menu ()
  (interactive)
  (setq dictionary-name-list nil)
  (setq m (create-popup-menu))
  (save-excursion
	(goto-char (point-min))
	(while (scan-buffer (concat *ebdict-dictionary-title-format* " \\(.*\\)([0-9]+)") :tail t :regexp t)
	  (push (cons (match-string 1) (point)) dictionary-name-list)))
  (setq dictionary-name-list (nreverse dictionary-name-list))
  (dolist (c dictionary-name-list)
	(let ((name (car c))
		  (pt (cdr c)))
	  (add-menu-item m
					 (make-symbol name)
					 name
					 #'(lambda () (interactive) (goto-char pt) (recenter 4)))))
  (track-popup-menu m))

(defun ebdict-output-next-definition ()
  (interactive)
  (forward-line)
  (let ((head (find-text-attribute 'heading :start (point))))
	(if head
		(progn
		  (goto-char head)
		  (recenter 4))
	  (ebdict-insert-result-more))))

(defun ebdict-output-previous-definition ()
  (interactive)
  (when (backward-line)
	(goto-eol))
  (let ((head (find-text-attribute 'heading :start (point-min)
								   :end (point) :from-end t)))
	(prog1
		(if (numberp head)
			(goto-char head)
		  nil)
	  (recenter 4))))

(defun ebdict-output-show-current-heading ()
  (interactive)
  (save-window-excursion
	(save-excursion
	  (ebdict-output-previous-definition)
	  (message "~A" (buffer-substring (point) (progn (goto-eol) (point)))))))

(defun ebdict-output-next-dictionary (&optional (arg 1))
  (interactive)
  (let ((cur-dic-path (get-buffer-alternate-file-name)))
	(if cur-dic-path
		;single dictionary search output
		(let* ((paths (ebdict-get-paths))
			   (idx (position cur-dic-path paths :test #'path-equal))
			   (idx-stop idx))
		  (while t
			(let ((newidx (+ idx arg)))
			  (if (>= newidx (length paths))
				  (setq newidx 0))
			  (if (eq newidx -1)
				  (setq newidx (1- (length paths))))
			  (when (= newidx idx-stop)
				(message "No match.")
				(return nil))
			  (if (and *ebdict-skip-no-hits*
					   (zerop (cdr (eb-count-hits *ebdict-last-query* (nth newidx paths)))))
				  (setq idx newidx)
				(progn
				  (ebdict-lookup-1 *ebdict-last-query* (nth newidx paths))
				  (return nil))))))
	  ;multiple dictionary search output
	  (progn
		(or (not (forward-line arg))
			(scan-buffer (concat "^" *ebdict-dictionary-title-format*)
						 :regexp t :reverse (minusp arg))
			(goto-char (point-max)))
		(recenter 4)))))

(defun ebdict-output-previous-dictionary ()
  (interactive)
  (ebdict-output-next-dictionary -1))

(defun ebdict-output-change-dictionary ()
  (interactive)
  (ebdict-lookup-menu *ebdict-last-query*))

(defun ebdict-output-quit ()
  (interactive)
  (if (> (count-windows) 1)
	  (delete-window)
	(bury-buffer)))

(defun ebdict-output-prev-page ()
  (interactive)
  (setq buffer-read-only nil)
  (handler-case (undo)
	(error (c)
	  (message "Can't undo.")))
  (setq buffer-read-only t))

(global-set-key #\C-M-\, 'ebdict-lookup)
(global-set-key #\C-M-. 'ebdict-lookup-across)
(global-set-key #\C-M-/ 'ebdict-lookup-menu)
(global-set-key #\C-M-: 'ebdict-lookup-regexp)





;; eb library dll management

;; (eb-lookup "WORD" "EPWINGDIR" :method METHOD)
;;   -> '(exec-code ("headding" "text") ("headding2" "text") ...)
;; WORD - 検索する単語。スペースもおｋ。最大128文字。
;; EPWINGDIR - CATALOG[S]ファイルがあるフォルダ
;; METHOD - 'forward (デフォルト), 'backward, 'exact (完全一致) のいずれか。

;; EXEC-CODE - 成功なら0。cdr部に検索結果のリスト。
;;             失敗なら-1。cdr部にはエラーメッセージ文字列

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "foreign"))

(defvar *eb-default-max-hits* 20)
(defvar *eb-default-text-length* 64111)

(c:define-c-type c:int EB_Error_Code)
(c:define-c-type c:int EB_Book)
(c:define-c-type c:int EB_Subbook_Code)
(c:define-c-type c:int EB_Appendix)
(c:define-c-type c:int EB_Hook_Code)

(c:define-c-struct EB_Position
  (:int32 page)
  (:int32 offset))

(c:define-c-struct EB_Hit
  (EB_Position heading)
  (EB_Position text))


(let ((dll (merge-pathnames "etc/eb.dll" (si:system-root))))
  (c:define-dll-entry c:string eb_error_message (EB_Error_Code)
	dll "eb_error_message")
  (c:define-dll-entry EB_Error_Code eb_initialize_library ()
	dll "eb_initialize_library")
  (c:define-dll-entry (c:void *) eb_finalize_library ()
	dll "eb_finalize_library")
  (c:define-dll-entry (c:void *) eb_initialize_book (EB_Book)
	dll "eb_initialize_book")
  (c:define-dll-entry (c:void *) eb_finalize_book (EB_Book)
	dll "eb_finalize_book")
  (c:define-dll-entry (c:void *) eb_initialize_appendix (EB_Appendix)
	dll "eb_initialize_appendix")
  (c:define-dll-entry EB_Error_Code eb_bind_appendix (EB_Appendix (c:char *))
	dll "eb_bind_appendix")
  (c:define-dll-entry (c:void *) eb_finalize_appendix (EB_Appendix)
	dll "eb_finalize_appendix")
  (c:define-dll-entry EB_Error_Code eb_appendix_subbook_list (EB_Book (EB_Subbook_Code *) (c:int *))
	dll "eb_appendix_subbook_list")
  (c:define-dll-entry EB_Error_Code eb_set_appendix_subbook (EB_Book EB_Subbook_Code)
	dll "eb_set_appendix_subbook")
  (c:define-dll-entry EB_Error_Code eb_bind (EB_Book (c:char *))
	dll "eb_bind")
  (c:define-dll-entry EB_Error_Code eb_subbook_list (EB_Book (EB_Subbook_Code *) (c:int *))
	dll "eb_subbook_list")
  (c:define-dll-entry EB_Error_Code eb_set_subbook (EB_Book EB_Subbook_Code)
	dll "eb_set_subbook")
  (c:define-dll-entry EB_Error_Code eb_search_word (EB_Book c:char*)
	dll "eb_search_word")
  (c:define-dll-entry EB_Error_Code eb_hit_list (EB_Book c:int (EB_Hit *) (c:int *))
	dll "eb_hit_list")
  (c:define-dll-entry EB_Error_Code eb_seek_text (EB_Book (EB_Position *))
	dll "eb_seek_text")
  (c:define-dll-entry EB_Error_Code eb_text (EB_Book (EB_Position *))
	dll "eb_text")
  (c:define-dll-entry EB_Error_Code eb_read_heading (EB_Book (EB_Position *) (EB_Appendix *) (c:void *) EB_Hook_Code c:int c:int)
	dll "eb_read_heading")
  (c:define-dll-entry EB_Error_Code eb_read_text (EB_Book (EB_Position *) (EB_Appendix *) (c:void *) EB_Hook_Code c:int c:int)
	dll "eb_read_text")
  (c:define-dll-entry EB_Error_Code eb_read_rawtext (EB_Book c:int c:int c:int)
	dll "eb_read_rawtext")
  (c:define-dll-entry EB_Error_Code eb_forward_text (EB_Book (EB_Appendix *))
	dll "eb_forward_text")
  (c:define-dll-entry EB_Error_Code eb_forward_heading (EB_Book)
	dll "eb_forward_heading")
  (c:define-dll-entry EB_Error_Code eb_tell_text (EB_Book (EB_Position *))
	dll "eb_tell_text")
  (c:define-dll-entry c:int eb_have_word_search (EB_Book)
	dll "eb_have_word_search")
  (c:define-dll-entry c:int eb_have_endword_search (EB_Book)
	dll "eb_have_endword_search")
  (c:define-dll-entry c:int eb_have_exactword_search (EB_Book)
	dll "eb_have_exactword_search")
  (c:define-dll-entry c:int eb_have_keyword_search (EB_Book)
	dll "eb_have_keyword_search")
  (c:define-dll-entry c:int eb_have_cross_search (EB_Book)
	dll "eb_have_cross_search")
  (c:define-dll-entry EB_Error_Code eb_search_keyword (EB_Book c:char)
	dll "eb_search_keyword")
  (c:define-dll-entry EB_Error_Code eb_search_cross (EB_Book (c:char *))
	dll "eb_search_cross")
  (c:define-dll-entry EB_Error_Code eb_search_endword (EB_Book (c:char *))
	dll "eb_search_endword")
  (c:define-dll-entry EB_Error_Code eb_search_exactword (EB_Book (c:char *))
	dll "eb_search_exactword")
  (c:define-dll-entry EB_Error_Code eb_is_text_stopped (EB_Book)
	dll "eb_is_text_stopped")
  (c:define-dll-entry EB_Error_Code eb_menu (EB_Book (EB_Position *))
	dll "eb_menu"))



;(c:define EB_MAX_HITS *eb-default-max-hits*)
(c:define EB_MAX_HEADING_LENGTH 127)
;(c:define EB_MAX_TEXT_LENGTH *eb-default-text-length*)
(c:define-c-type c:u_long NULL)
(c:define NULL 0)

(setq *eb-book-buffer-size* 65000) ;適当

(defun eb-epwing-directory-p (dir)
  "Checks if DIR is EPWING directory. Returns t if DIR is EPWING.

EPWING directory is the folder with CATALOGS file in it."
  (when dir
	(let ((book (si:make-chunk nil *eb-book-buffer-size*))
		  (path (si:make-string-chunk (truename dir))))
	  (eb_initialize_library)
	  (eb_initialize_book book)
	  (setq result (eb_bind book path))
	  (eb_finalize_book book)
	  (eb_finalize_library)
	  (eq result 0))))


(defun eb-lookup (word dir &key method max from)
  "Search TERM in EPWING dictionary located at DIR.

Returns '(exec-code . '((headword . definition) (headword . definition)..))
DIR is the path to the CATALOGS file.
method can be 'forward, 'backword, and 'exact. keyword and cross not supported.
Assumes 'forward when omitted."
  (interactive)
  (handler-case
	  (let (result)
		(setq book (eb-setup-book dir))
		(setq app (eb-setup-appendix dir))
		(setq result (eb-get-defs book word method max from app))
		(eb_finalize_appendix app)
		(eb_finalize_book book)
		(eb_finalize_library)
		(return-from eb-lookup (cons 0 result)))
	(error (c)
	  (eb_finalize_book book)
	  (eb_finalize_library)
	  (return-from eb-lookup (eb-process-error c)))))

(defun eb-get-defs (book word method max &optional from appendix)

  (when (> (length word) 127)
	(error "Error search query too long."))

  (case method
	(backward
	 (setq search-fn 'eb_search_endword)
	 (setq term (eb-chunk-simple word)))
	(exact
	 (setq search-fn 'eb_search_exactword)
	 (setq term (eb-chunk-simple word)))
	(keyword
	 (setq search-fn 'eb_search_keyword)
	 (setq term (eb-chunk-compound word)))
	(cross
	 (setq search-fn 'eb_search_cross)
	 (setq term (eb-chunk-compound word)))
	(t
	 (setq search-fn 'eb_search_word)
	 (setq term (eb-chunk-simple word))))

  (unless (zerop (setq error_code (funcall search-fn book term)))
	(error "Error searching word. ~A" error_code))

  (when (or (not max)
			(not (numberp max))
			(minusp max)
			(zerop max))
	(setq max *eb-default-max-hits*))

  (setq max-sub (if from 600 (* max 2)))
  (setq from (or from 0))
  (setq result nil)
  (setq dupe-check-list nil)
  (setq position-text-list nil)

  (while t
	(setq hits (si:make-chunk nil (* 16 max-sub)))
	(setq hit_count (si:make-chunk nil 256))
	(unless (zerop (setq error_code (eb_hit_list book max-sub hits hit_count)))
	  (error "Error retrieving results. ~A" error_code))
	(setq hit-count (si:unpack-int32 hit_count 0))

	(when (or (eq hit-count 0) (> (length position-text-list) max-sub))
	  (return result))

	(setq heading-chunk (si:make-chunk nil 128))
	(setq heading_length (si:make-chunk nil 4))
	(dotimes (x hit-count)
	  (setq hit (make-EB_Hit hits (* 16 x)))
	  (setq position-heading (EB_Hit-heading hit))
	  (setq position-text (EB_Hit-text hit))

	  (unless (zerop (setq error_code (eb_seek_text book position-heading)))
		(error "Error seeking for heading. ~A" error_code))

	  (unless (zerop (setq error_code (eb_read_heading book appendix NULL NULL EB_MAX_HEADING_LENGTH heading-chunk heading_length)))
		(error "Error reading heading. ~A" error_code))

	  (setq heading (map-euc-to-internal (si:unpack-string heading-chunk 0 128)))

	  ;dupe check
	  (setq position-info (cons heading (+ (* (EB_Position-page position-text) 2048) (EB_Position-offset position-text))))
	  (unless (find position-info dupe-check-list :test 'equal)
		(setq dupe-check-list (append dupe-check-list (list position-info)))
		(setq position-text-list (append position-text-list (list (cons heading position-text)))))))
  
  ;(user::m "~A" position-text-list)
  (dotimes (x (length position-text-list))
	(setq text-chunk (si:make-chunk nil *eb-default-text-length*))
	(setq text_length (si:make-chunk nil 32))
	(setq position-text (cdr (nth x position-text-list)))
	(setq heading (car (nth x position-text-list)))
	(when (>= x from)
		(unless (zerop (setq error_code (eb_seek_text book position-text)))
		  (error "Error seeking for text. ~A" error_code))

		(unless (zerop (setq error_code (eb_read_text book appendix NULL NULL *eb-default-text-length* text-chunk text_length)))
		  (error "Error reading text. ~A" error_code))

		(setq text (map-euc-to-internal (si:unpack-string text-chunk 0 *eb-default-text-length*)))

		
		;If retrieved text is longer than default text lenght, keep reading the overflown text.
		(while (eq (si:unpack-int32 text_length 0) *eb-default-text-length*)
		  (unless (zerop (setq error_code (eb_read_text book NULL NULL NULL *eb-default-text-length* text-chunk text_length)))
			(error "Error reading overflowing text. ~A" error_code))
		  (setq addition (si:unpack-string text-chunk 0 *eb-default-text-length*))
		  (setq addition (map-euc-to-internal addition))
		  (setq text (concat text addition)))

		
		  (setq result (append result (list (cons heading text)))))
		(when (= (length result) max)
		  (return-from eb-get-defs result))
		)

  result)

(defun eb-count-hits (word dir &key method max)
  "Count WORD in dictionary located at DIR.

Returns (0 . hits) if successful, otherwise (-1 . error-string) .
car of the result is error-code. cdr is the actual count.
DIR is the path to the CATALOGS file.
method can be one of 'forward, 'backword, 'exact, 'keyword and 'cross.
'multi not supported. Assumes 'forward when METHOD is omitted.
Assumes first subbook."
  (interactive)
  (handler-case
	  (progn
		(setq book (eb-setup-book dir))
		(setq app (eb-setup-appendix dir))
		(setq result (eb-get-defs book word method max nil app))
		(setq hits (cons 0 (length result)))
		(eb_finalize_book book)
		(eb_finalize_library)
		(return-from eb-count-hits hits))
	(error (c)
	  (eb_finalize_book book)
	  (eb_finalize_library)
	  (return-from eb-count-hits (eb-process-error c)))))

(defun eb-enumerate (fn dir)
  "Enumerate all entries of the dictionary in DIR with FN.

DIR is the path containing EPWING dictionary. FN is a function
that takes heading and text as arguments.

example:  (eb-enumerate #'(lambda (heading text) (< (length text 20)))
						\"C:/dic/webster1913\")
"
  (handler-case
	  (let (result)
		(setq book (eb-setup-book dir))
		(setq result (eb-enum-defs book fn))
		(eb_finalize_book book)
		(eb_finalize_library)
		result)
	(error (c)
	  (eb_finalize_book book)
	  (eb_finalize_library)
	  (eb-process-error c))))

(defun eb-enum-defs (book fn)
  (let ((init-pos (make-EB_Position))
		(text-chunk (si:make-chunk nil *eb-default-text-length*))
		(text-length (si:make-chunk nil 32))
		(total 0)
		result)
	(eb_text book init-pos)
	(eb_seek_text book init-pos)
	(while t
	  (unless (zerop (setq error_code (eb_read_text book NULL NULL NULL *eb-default-text-length* text-chunk text-length)))
		(error "Error reading text. ~A" error_code))
	  (setq text (map-euc-to-internal (si:unpack-string text-chunk 0 *eb-default-text-length*)))
	  ;If retrieved text is longer than default text lenght,
	  ;keep reading the overflown text.
	  (while (eq (si:unpack-int32 text-length 0) *eb-default-text-length*)
		(unless (zerop (setq error_code (eb_read_text book NULL NULL NULL *eb-default-text-length* text-chunk text-length)))
		  (error "Error reading overflowing text. ~A" error_code))
		(setq addition (si:unpack-string text-chunk 0 *eb-default-text-length*))
		(setq addition (map-euc-to-internal addition))
		(setq text (concat text addition)))

	  (setq total (1+ total))
	  (setq text-list (split-string text "\n"))
	  (setq heading (car text-list))
	  (setq text (substring text (1+ (length heading))))

	  (when (funcall fn heading text)
		(push (cons heading text) result))

	  (setq err-code (eb_forward_text book 0))
	  (when (eq err-code 61)
		(message "enumerate: ~5@Ahits/~A ...done." (length result) total)
		(return-from eb-enum-defs (reverse result)))
	  (when (zerop (mod total 500))
		(message "enumerate: ~5@Ahits/~A" (length result) total)))))

(defun eb-chunk-compound (word)
  "Return array chunk made from multi-word string for keyword and cross search"
  (let* ((word-list (split-string word " "))
		 (array (si:make-chunk nil 128))
		 (offset 0))
	(si:clear-chunk array)
	(dolist (w word-list)
	  (setq chunk (si:make-string-chunk (map-internal-to-euc w)))
	  (si:pack-int32 array offset (si:chunk-data chunk))
	  (setq offset (+ offset 4)))
	array))

(defun eb-chunk-simple (word)
  "Return chunk for forward, backward, exact search"
  (si:make-string-chunk (map-internal-to-euc word)))


(defun eb-setup-book (dir)
  "Return book object with DIR bound to it.

Subbook[0] is selected in all cases."
  (setq book (si:make-chunk nil 61000))
  (setq subbook_code (si:make-chunk nil 32))
  (setq subbook_count (si:make-chunk nil 32))
  (eb_initialize_library)
  (eb_initialize_book book)
  ; set path AFTER initialization to prevent segfault.
  (setq path (si:make-string-chunk (truename dir)))

  ;bind path to book
  (unless (zerop (setq error_code (eb_bind book path)))
	(error "Error binding path. ~A" error_code))
  ;retrieve list of subbooks
  (unless (zerop (setq error_code (eb_subbook_list book subbook_code subbook_count)))
	(error "Error retrieving subbook list. ~A" error_code))
  ;select first subbook
  (setq subbook_code (si:unpack-int8 subbook_code 0))
  (unless (zerop (setq error_code (eb_set_subbook book subbook_code)))
	(error "Error setting subbook. ~A" error_code))
  book
  )

(defun eb-setup-appendix (dir)
  "Return appendix object with DIR bound to it.

Subbook[0] is selected in all cases."
  (setq appendix (si:make-chunk nil 61000))
  (setq subbook_code (si:make-chunk nil 32))
  (setq subbook_count (si:make-chunk nil 32))
  (eb_initialize_appendix appendix)
  ; set path AFTER initialization to prevent segfault.
  (setq path (si:make-string-chunk (truename dir)))

  ;bind path to book
  (unless (zerop (setq error_code (eb_bind_appendix appendix path)))
	(error "Error binding path. ~A" error_code))
  ;retrieve list of subbooks
  (unless (zerop (setq error_code (eb_appendix_subbook_list appendix subbook_code subbook_count)))
	(error "Error retrieving subbook list. ~A" error_code))
  ;select first subbook
  (setq subbook_code (si:unpack-int8 subbook_code 0))
  (eb_set_appendix_subbook appendix subbook_code)
  appendix)

(defun eb-set-subbook (book nth)
  "Set subbook of BOOK to NTH. Returns book object."
  (setq subbook_code (si:make-chunk nil 32))
  (setq subbook_count (si:make-chunk nil 32))
  (unless (zerop (setq error_code (eb_subbook_list book subbook_code subbook_count)))
	(error "Error retrieving subbook list. ~A" error_code))
  ;select first subbook
  (setq subbook_code (si:unpack-int8 subbook_code (* 4 (or nth 0))))
  (unless (zerop (setq error_code (eb_set_subbook book subbook_code)))
	(error "Error setting subbook. ~A" error_code))
  book)

(defun eb-get-subbook-count (book)
  "Return number of subbooks in BOOK."
  (setq subbook_code (si:make-chunk nil 32))
  (setq subbook_count (si:make-chunk nil 32))
  (unless (zerop (setq error_code (eb_subbook_list book subbook_code subbook_count)))
	(error "Error retrieving subbook list. ~A" error_code))
  (si:unpack-int8 subbook_count 0))

(defun eb-process-error (c)
  (cons -1 (si:*condition-string c)))

(defun ptr-string (address)
  "メモリ上のADDRESSにある文字列をlisp文字列にして返す。"
  (si:unpack-string (si:make-chunk 'string 256 nil address) 0))



(defvar *eb-aspell-dll-file* "aspell-15.dll")
(defvar *eb-aspell-path* "C:/Program Files/Aspell")
(defvar *eb-aspell-lang* "en_US")

(c:define-c-type c:int AS_CONFIG)
(c:define-c-type c:int AS_SPELLER)
(c:define-c-type c:int AS_WORDLIST)
(c:define-c-type c:int AS_STRENUM)

(let ((dll (merge-pathnames (concat "etc/" *eb-aspell-dll-file*) (si:system-root))))
  (c:define-dll-entry AS_CONFIG new_aspell_config ()
	dll "new_aspell_config")
  (c:define-dll-entry c:string delete_aspell_config (AS_CONFIG)
	dll "delete_aspell_config")
  (c:define-dll-entry AS_SPELLER new_aspell_speller (AS_CONFIG)
	dll "new_aspell_speller")
  (c:define-dll-entry c:int to_aspell_speller (AS_CONFIG)
	dll "to_aspell_speller")
  (c:define-dll-entry c:int aspell_speller_check (AS_CONFIG (c:char *) c:int)
	dll "aspell_speller_check")
  (c:define-dll-entry c:int aspell_config_replace (AS_CONFIG (c:char *) (c:char *))
	dll "aspell_config_replace")
  (c:define-dll-entry (c:char *) aspell_config_retrieve (AS_CONFIG (c:char *))
	dll "aspell_config_retrieve")
  (c:define-dll-entry (c:char *) aspell_config_error_message (AS_CONFIG)
	dll "aspell_config_error_message")
  (c:define-dll-entry c:int aspell_error_number (AS_CONFIG)
	dll "aspell_error_number")
  (c:define-dll-entry (c:char *) aspell_error_message (AS_CONFIG)
	dll "aspell_error_message")
  (c:define-dll-entry (c:char *) aspell_speller_error_message (AS_SPELLER)
	dll "aspell_speller_error_message")
  (c:define-dll-entry AS_WORDLIST aspell_speller_suggest (AS_SPELLER (c:char *) c:int)
	dll "aspell_speller_suggest")
  (c:define-dll-entry AS_STRENUM aspell_word_list_elements (AS_WORDLIST)
	dll "aspell_word_list_elements")
  (c:define-dll-entry c:int aspell_string_enumeration_next (AS_STRENUM)
	dll "aspell_string_enumeration_next")
  (c:define-dll-entry c:int delete_aspell_string_enumeration (AS_STRENUM)
	dll "delete_aspell_string_enumeration"))

(defun aspell-config-replace (ac key value)
  (aspell_config_replace ac (si:make-string-chunk key) (si:make-string-chunk value)))

(defun aspell-config-retrieve (ac key)
  (setq addr (aspell_config_retrieve ac (si:make-string-chunk key)))
  (setq chunk (si:make-chunk 'string 128 nil addr))
  (si:unpack-string chunk 0 128))

(defun aspell-config-error-message (ac)
  (setq addr (aspell_config_error_message ac))
  (setq chunk (si:make-chunk 'string 256 nil addr))
  (si:unpack-string chunk 0 256))

(defun aspell-speller-error-message (sp)
  (setq addr (aspell_speller_error_message sp))
  (setq chunk (si:make-chunk 'string 256 nil addr))
  (si:unpack-string chunk 0 256))

(defun aspell-error-message (sp)
  (setq addr (aspell_error_message sp))
  (setq chunk (si:make-chunk 'string 256 nil addr))
  (si:unpack-string chunk 0 256))

(defun aspell-convert-encoding (str &optional encoding)
  (save-excursion
	(let ((temp-file (make-temp-file-name)))
	  (set-buffer (get-buffer-create " *conv*"))
	  (delete-region (point-min) (point-max))
	  (insert str)
	  (set-buffer-file-name temp-file)
	  (save-buffer *encoding-binary*)
	  (revert-buffer (or encoding (aspell-coding)))
	  (write-file temp-file t nil *encoding-utf8*)
	  (revert-buffer)
	  (prog1
		  (buffer-substring (point-min) (point-max))
		(delete-file temp-file :if-does-not-exist :skip)
		(delete-buffer (find-buffer " *conv*"))))))

;; borrowed from aspell.l
(defmacro case-string (str &body ls)
  (let ((gstr (gensym)))
	`(let ((,gstr ,str))
	   (cond
		,@(mapcar #'(lambda (x)
					  `(,(if (atom (car x))
							 `(string= ,gstr ,(car x))
						   `(or ,@(mapcar #'(lambda (y) `(string= ,y ,gstr)) (car x))))
						,(second x)))
				  ls)))))

(defmacro aspell-code-selection (&rest ls)
  `(case-string (substring *eb-aspell-lang* 0 2)
				(("en" "fr" "de" "da" "es" "it" "nl" "no" "sv") ,(first ls))
				(("cs" "pl" "pt" "ro" "sk") ,(second ls))
				("ru" ,(third ls))
				("el" ,(fourth ls))))

(defun aspell-coding ()
  (aspell-code-selection
   *encoding-iso-8859-1*
   *encoding-iso-8859-2*
   *encoding-iso-8859-5*
   *encoding-iso-8859-7*))
;; aspell.l

(defun ebdict-aspell (word)
  (let ((ac (new_aspell_config))
		(dic-dir (merge-pathnames "dict" *eb-aspell-path*))
		(data-dir (merge-pathnames "data" *eb-aspell-path*)))
	(aspell-config-replace ac "dict-dir" dic-dir)
	(aspell-config-replace ac "data-dir" data-dir)
	(aspell-config-replace ac "lang" *eb-aspell-lang*)

	(setq sp (new_aspell_speller ac))
	(when (/= (aspell_error_number sp) 0)
	  (setq err-msg (format nil "Aspell error: ~A" (aspell-error-message sp)))
	  (return-from ebdict-aspell (list err-msg)))
	(setq sc (to_aspell_speller sp))
	(setq wlen (length word))
	(setq wchunk (si:make-string-chunk word))
	(prog1
		(case (aspell_speller_check sc wchunk wlen)
		  (0
		   (let (result)
			 (setq a (aspell_speller_suggest sc wchunk wlen))
			 (setq b (aspell_word_list_elements a))
			 (while (/= (setq word-addr (aspell_string_enumeration_next b)) 0)
			   (setq chunk (si:make-chunk 'string 256 nil word-addr))
			   (push (si:unpack-string chunk 0 256) result))
			 (delete_aspell_string_enumeration b)
			 (reverse result)))
		  (1
		   nil)
		  (t
		   (error "error in aspell.")))
	  (delete_aspell_config ac))))
