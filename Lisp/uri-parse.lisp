;;; -*- Mode: Common Lisp -*-
;;; uri-parse.lisp

;;; Darion Mance 869239

(defstruct url scheme userinfo host port path query fragment)


;; conversione da stringa a lista
(defun str-to-list (stringa)
  (coerce stringa 'list))


;; conversione da lista a stringa
(defun list-to-str (lista)
  (coerce lista 'string))


(defun uri-parse (uri-string)
  (let*
      ((scheme
        (multiple-value-list
 	 (get-scheme
	  (str-to-list (string-downcase uri-string)))))
       (userinfo
	(multiple-value-list
	 (get-userinfo
	  (second scheme) (first scheme) 0)))
       (host
	(multiple-value-list
	 (get-host (second userinfo) (first scheme))))
       (port
	(multiple-value-list
	 (get-port (second host) (first scheme) 0)))
       (path
	(multiple-value-list
	 (get-path (second port) (first scheme))))
       (query
	(multiple-value-list
	 (get-query (second path) 0)))
       (fragment
	(multiple-value-list
	 (get-fragment (second query) 0))))
    ;;   expression
    (make-url
     :scheme (first scheme)
     :userinfo (first userinfo)
     :host (first host)
     :port (first port)
     :path (first path)
     :query (first query)
     :fragment (first fragment))))


(defun uri-display (uri &optional (stream T))
  (format stream
          "Scheme: ~S 
           Userinfo: ~S
           Host: ~S
           Port: ~D
           Path: ~S
           Query: ~S
           Fragment: ~S"
	  (uri-scheme uri)
	  (uri-userinfo uri)
	  (uri-host uri)
	  (uri-port uri)
	  (uri-path uri)
	  (uri-query uri)
	  (uri-fragment uri))
  t)


;;---------;---------;---------;---------;---------;
;; analisi dello scheme

(defun get-scheme (uri &optional scheme)
  (if (not (null uri))
      (cond
       ((or
	 (string= (first uri) "@") (string= (first uri) "/")
	 (string= (first uri) "?") (string= (first uri) "#")
	 (string= (first uri) " "))
	(error "Scheme con char invalido!"))
       ((and (string= (first uri) ":") (equal scheme nil))
	(error "Scheme inesistente!"))
       ((and (string= (first uri) ":"))
	(values (list-to-str scheme) (cdr uri)))
       ((not (string= (first uri) ":"))
	(get-scheme
	 (cdr uri)
	 (append scheme (cons (first uri) nil)))))
    ;; else
    (error "URI vuoto/errato!")))


;;---------;---------;---------;---------;---------;
;;  analisi dell'userinfo

;; Controlla se @ e' in lista. Se esiste ritorna t altrimenti nil
(defun userinfo-exists (uri)
  (if (not (null uri))
      (cond
       ((string= (first uri) "@") t)
       ((not (string= (first uri) "@"))
	(userinfo-exists (cdr uri)))) 
    ;; else
    nil))


;; Funzione di controllo di USERINFO per SCHEME MAILTO
(defun userinfo-mailto (uri userinfo flag)
  (if (and (null uri) (= flag 0))
      (values nil nil))
  (if (userinfo-exists uri)
      (cond
       ((and (string= (first uri) "@") (null (cdr uri)))
        (error "Userinfo-mailto non valido!"))
       ((or (string= (first uri) ":") (string= (first uri) "/")
	    (string= (first uri) "?") (string= (first uri) "#")
	    (string= (first uri) " "))
	(error "Userinfo-mailto con char invalido!"))
       ((not (string= (first uri) "@"))
	(userinfo-mailto
	 (cdr uri)
	 (append userinfo (cons (first uri) nil)) 1))
       ((and (string= (first uri) "@") (not (null (cdr uri))))
	(values (list-to-str userinfo) (cdr uri))))
    ;; else
    (cond
     ((or (string= (first uri) ":") (string= (first uri) "/")
	  (string= (first uri) "?") (string= (first uri) "#")
	  (string= (first uri) " "))
      (error "Userinfo-mailto con char invalido!"))
     ((null uri)
      (values (list-to-str userinfo) nil))
     ((not (null uri))
      (userinfo-mailto
       (cdr uri)
       (append userinfo (cons (first uri) nil)) 1)))))


;; Funzione di controllo di USERINFO per SCHEME TEL e FAX
(defun userinfo-tel-fax (uri userinfo flag)
  (cond
   ((and (null uri) (= flag 0)) nil)
   ((or (string= (first uri) ":") (string= (first uri) "/")
	(string= (first uri) "?") (string= (first uri) "#")
	(string= (first uri) " ") (string= (first uri) "@"))
    (error "Userinfo-tel-fax con char invalido!"))
   ((not (null uri))
    (userinfo-tel-fax
     (cdr uri)
     (append userinfo (cons (first uri) nil)) 1))
   ((and (null uri))
    (values (list-to-str userinfo) nil))))


;; Funzione di controllo di USERINFO di DEFAULT
(defun get-userinfo (uri scheme flag &optional userinfo)
  (if (not (null uri))
      (cond
       ((string= scheme "news")
	(values nil uri))
       ((string= scheme "mailto")
	(userinfo-mailto uri userinfo 0))
       ((or (string= scheme "tel") (string= scheme "fax"))
	(userinfo-tel-fax uri userinfo 0))
       ((and (string= (first uri) "/")
	     (not (string= (second uri) "/")))
	(values nil uri))
       ((and (not (userinfo-exists uri)) (= flag 0))
	(values nil uri))
       ((and (userinfo-exists uri) (= flag 0)
	     (string= (first uri) "/") (string= (second uri) "/")
	     (string= (third uri) "@"))
	(error "Userinfo non puo' essere nullo!"))
       ((and (userinfo-exists uri) (= flag 0)
	     (string= (first uri) "/") (string= (second uri) "/"))
	(get-userinfo (cdr (cdr uri)) scheme 1 userinfo))
       ((or (string= (first uri) ":") (string= (first uri) "/")
  	    (string= (first uri) "?") (string= (first uri) "#")
   	    (string= (first uri) " "))
	(error "Authority/Userinfo con char invalido!"))
       ((and (string= (first uri) "@") (null (cdr uri)) (= flag 1))
	(error "La uri non puo' finire con userinfo@!"))
       ((and (not (string= (first uri) "@")) (= flag 1))
	(get-userinfo
	 (cdr uri)
	 scheme
	 1
	 (append userinfo (cons (first uri) nil))))
       ((and (string= (first uri) "@") (= flag 1))
	(values (list-to-str userinfo) (cdr uri))))
    ;; else
    (values nil nil)))


;;---------;---------;---------;---------;---------;
;; analisi dell'host

;; Da chiamare quando scheme e' news
(defun get-news-mailto-host (uri host flag)
  (if (and (null uri) (= flag 0)) 
      (values nil nil)
    (cond
     ((and (string= (first uri) ".") (string= (second uri) "."))
      (error "Host-news-mailto con due . vicini e' errato!"))
     ((or (string= (first uri) "/") (string= (third uri) ":")
	  (string= (first uri) "#") (string= (first uri) "@")
	  (string= (first uri) "?") (string= (first uri) " "))
      (error "Host-news-mailto con char invalido!"))
     ((null (cdr uri))
      (values
       (coerce (append host (cons (first uri) nil)) 'string)
       nil))
     ((not (null uri))
      (get-news-mailto-host
       (cdr uri)
       (append host (cons (first uri) nil))
       1)))))


;; Funzione di default per host
(defun get-default-host (uri host flag)
  (cond
   ((and (string= (first uri) ".") (string= (second uri) "."))
    (error "Host con due . vicini e' errato!"))
   ((or (and (string= (first uri) "/") (string= (second uri) "/")
	     (or (string= (third uri) "/") (string= (third uri) ":")
		 (string= (third uri) "#") (string= (third uri) "@")
		 (string= (third uri) ".") (string= (third uri) "?")
		 (string= (third uri) " "))
	     (= flag 0)))
    (error "L'host non puo' cominciare con char invalidi!"))
   ((and (string= (first uri) "/") (string= (second uri) "/")
	 (= flag 0))
    (get-default-host (cdr (cdr uri)) host 1))
   ((and (string= (first uri) "/") (not (string= (second uri) "/"))
	 (= flag 0))
    (values nil uri))
   ((and (= flag 1) (string= (first uri) ".")
	 (characterp (second uri)))
    (get-default-host
     (cdr uri)
     (append host (cons (car uri) nil))
     1))
   ((or (string= (first uri) "?") (string= (first uri) "@")
	(string= (first uri) "#") (string= (first uri) " ")
	(string= (first uri) "."))
    (error "Host con char invalido!"))
   ((and (= flag 0) (characterp (first uri)) (null (cdr uri)))
    (values (list-to-str (first uri)) nil))
   ((and (= flag 0) (characterp (first uri)))
    (get-default-host
     (cdr uri)
     (append host (cons (car uri) nil))
     1))
   ((and (string= (first uri) "/") (= flag 1) (null (cdr uri)))
    (values (list-to-str host) nil))
   ((and (or (string= (first uri) ":") (string= (first uri) "/"))
	 (= flag 1))
    (values (list-to-str host) uri))
   ((and (null (cdr uri)) (= flag 1))
    (values (list-to-str (append host(cons (first uri) nil)))
	    nil))
   ((and (not (null (cdr uri))) (= flag 1))
    (get-default-host
     (cdr uri)
     (append host (cons (car uri) nil))
     1))))

(defun get-host (uri scheme)
  (if (or (string= scheme "news") (string= scheme "mailto"))
      (get-news-mailto-host uri (list) 0)
    ;; else
    (get-default-host uri (list) 0)))


;;---------;---------;---------;---------;---------;
;; analisi del port

(defun get-port (uri scheme flag &optional port)
  (if (or (string= scheme "tel") (string= scheme "fax")
	  (string= scheme "mailto") (string= scheme "news"))
      (values (parse-integer (list-to-str '(#\8 #\0))) uri)
    ;; else
    (if (not (null uri))
	(cond
	 ((and (not (string= (first uri) ":")) (= flag 0))
	  (values (parse-integer (list-to-str '(#\8 #\0))) uri))
	 ((and (string= (first uri) ":") (null (cdr uri)) (= flag 0))
	  (error "Porta inesistente!"))
	 ((and (string= (first uri) ":") (string= (second uri) "/")
	       (= flag 0))
	  (error "Porta non valida!"))
	 ((and (string= (first uri) ":") (= flag 0))
	  (get-port (cdr uri) scheme 1 port))
	 ((or (string= (first uri) "?") (string= (first uri) "@")
	      (string= (first uri) "#") (string= (first uri) " ")
	      (string= (first uri) ":") (string= (first uri) "."))
	  (error "Porta con char invalido!"))
	 ((and (string= (first uri) "/") (= flag 1))
	  (values (parse-integer (list-to-str port)) uri))
	 ((and (null (cdr uri)) (= flag 1))
	  (values
	   (parse-integer
	    (list-to-str
	     (append port (cons (car uri) nil)))) nil))
	 ((and (not (null (cdr uri))) (= flag 1))
	  (get-port
	   (cdr uri)
	   scheme
	   1
	   (append port (cons (car uri) nil)))))
      ;; else
      (values (parse-integer (list-to-str '(#\8 #\0))) nil))))


;;---------;---------;---------;---------;---------;
;; analisi della path

(defun get-zos-subpath (uri path path-length)
  (if (not (null uri))
      (cond
       ((and (string= (first uri) "(") (string= (second uri) ")"))
	(error "Sub-path-zos non puo' essere vuota!"))
       ((and (string= (first uri) "(") (null (cdr uri)))
	(error "Sub-path-zos errata/inesistente!"))
       ((and (string= (first uri) ")") (not (null (cdr uri)))
	     (alphanumericp (first (cdr uri))))
	(error "Dopo ) non puoi avere altri caratteri!"))
       ((string= (first uri) "(")
	(get-zos-subpath
	 (cdr uri)
	 (append path (cons (car uri) nil))
	 path-length))
       ((string= (first uri) ")")
	(if (>
	     (length
	      (subseq
	       (list-to-str
		(append path (cons (car uri) nil)))
	       path-length))
	     10)
	    (error "<id8> (path-zos) e' piu' lungo di 8 char!")
	  (values 
	   (list-to-str (append path (cons (car uri) nil)))
	   (cdr uri))))
       ((not (string= (first uri) ")"))
	(get-zos-subpath
	 (cdr uri)
	 (append path (cons (car uri) nil))
	 path-length))
       ((null (cdr uri))
	(error "Sub-path-zos deve finire con )!"))
       ((not (alphanumericp (first uri)))
	(error "Sub-path-zos con char invalido!")))
    ;; else
    (error "Sub-path-zos invalida!!!")))


(defun get-zos-path (uri path flag)
  (if (not (null uri))
      (cond
       ((and (string= (first uri) "/") (null (cdr uri)) (= flag 0))
	(error "Path-zos inesistente!"))
       ((and (string= (first uri) "/") (string= (second uri) "."))
	(error "Path-zos non deve cominciare con '.'"))
       ((and (string= (first uri) "/")
	     (or (string= (second uri) "?")
		 (string= (second uri) "#"))
	     (= flag 0))
	(error "Path-zos inesistente!"))
       ((and (string= (first uri) "/") (= flag 0))
	(get-zos-path (cdr uri) path 1))
       ((and (= flag 1) (string= (first uri) ".")
	     (not (null (cdr uri))))
	(get-zos-path
	 (cdr uri)
	 (append path (cons (car uri) nil))
	 1))
       ((and (or (string= (first uri) "?") (string= (first uri) "#"))
	     (= flag 1))
	(if (> (length (coerce path 'string)) 44)
	    (error "<id44> (path-zos) e' piu' lungo di 44 char!")
	  (values (list-to-str path) uri)))
       ((and (string= (first uri) "(") (= flag 1))
	(if (> (length (list-to-str path)) 44)
	    (error "<id44> (path-zos) e' piu' lungo di 44 char!")
	  (get-zos-subpath uri path (length (list-to-str path)))))
       ((not (alphanumericp (first uri)))
	(error "Path-zos con char invalido!"))
       ((and (null (cdr uri)) (= flag 1))
	(if (>
	     (length
	      (coerce (append path (cons (car uri) nil)) 'string))
	     44)
	    (error "<id44> (path-zos) e' piu' lungo di 44 char!")
	  (values
	   (coerce (append path (cons (car uri) nil)) 'string)
	   nil)))
       ((and (not (null (cdr uri))) (= flag 1))
	(get-zos-path
	 (cdr uri)
	 (append path (cons (car uri) nil))
	 1)))
    ;; else
    (error "Path-zos deve essere presente!")))


(defun get-default-path (uri path flag)
  (if (not (null uri))
      (cond
       ((and (string= (first uri) "/") (string= (second uri) "/"))
	(error "Path con due / vicini e' errato!"))
       ((and (string= (first uri) "/") (null (cdr uri)) (= flag 0))
	(error "Path inesistente!"))
       ((and (string= (first uri) "/") (string= (second uri) " ")
	     (= flag 0))
	(error "Non deve esserci lo spazio ad inizio path!"))
       ((and (string= (first uri) "/")
	     (or (string= (second uri) "?")
		 (string= (second uri) "#"))
	     (= flag 0))
	(values nil (cdr uri)))
       ((and (string= (first uri) "/") (= flag 0))
	(get-default-path (cdr uri) path 1))
       ((and (string= (first uri) "/") (= flag 1) (null (cdr uri)))
	(error "La path non puo' finire con /"))
       ((and (or (string= (first uri) "/")
		 (string= (first uri) " "))
	     (or (string= (second uri) "?")
		 (string= (second uri) "#"))
	     (= flag 1))
	(error "La path non puo' finire cosi!"))
       ((and (string= (first uri) " ") (not (null (cdr uri)))
	     (= flag 1))
	(get-default-path (cdr uri) (append path '(#\% #\2 #\0)) 1))
       ((or (string= (first uri) " ") (string= (first uri) "@")
	    (string= (first uri) ":"))
	(error "Path con char invalido!"))
       ((and (or (string= (first uri) "?")
		 (string= (first uri) "#"))
	     (= flag 1))
	(values (list-to-str path) uri))
       ((and (null (cdr uri)) (= flag 1))
	(values
	 (coerce (append path (cons (car uri) nil)) 'string)
	 nil))
       ((and (not (null (cdr uri))) (= flag 1))
	(get-default-path
	 (cdr uri)
	 (append path (cons (car uri) nil))
	 1)))
    ;; else
    (values nil nil)))


(defun get-path (uri scheme)
  (if (string= scheme "zos")
      (get-zos-path uri (list) 0)
    ;; else
    (get-default-path uri (list) 0)))


;;---------;---------;---------;---------;---------;
;; analisi della query

(defun get-query (uri flag &optional query)
  (if (not (null uri))
      (cond
       ((or (and (string= (first uri) "?") (string= (second uri) "#")
		 (= flag 0))
	    (and (string= (first uri) "?")
		 (null (cdr uri))
		 (= flag 0)))
	(error "Query inesistente!"))
       ((and (string= (first uri) "#") (= flag 0))
	(values nil uri))
       ((and (or (string= (first uri) "?")
		 (string= (first uri) "#"))
	     (string= (second uri) " ") (= flag 0))
	(error "Non deve esserci spazio ad inizio query/fragment!"))
       ((and (string= (first uri) "?") (= flag 0))
	(get-query (cdr uri) 1 query))
       ((and (string= (first uri) " ") (string= (second uri) "#")
	     (= flag 1))
	(error "Non deve esserci spazio a fine query!")) 
       ((and (string= (first uri) " ") (not (null (cdr uri)))
	     (= flag 1))
	(get-query (cdr uri) 1 (append query '(#\% #\2 #\0))))
       ((and (string= (first uri) " ") (null (cdr uri))
	     (= flag 1))
	(error "La query non puo' finire con uno spazio"))
       ((and (string= (first uri) "#") (= flag 1))
	(values (list-to-str query) uri))
       ((and (null (cdr uri)) (= flag 1))
	(values
	 (coerce (append query (cons (car uri) nil)) 'string)
	 nil))
       ((and (not (null (cdr uri))) (= flag 1))
	(get-query
	 (cdr uri)
	 1
	 (append query (cons (car uri) nil)))))
    ;; else
    (values nil nil)))


;;---------;---------;---------;---------;---------;
;; analisi del fragment

(defun get-fragment (uri flag &optional fragment)
  (if (not (null uri))
      (cond
       ((and (= flag 0) (string= (first uri) "#") (null (cdr uri)))
	(error "Fragment inesistente!"))
       ((and (string= (first uri) "#") (string= (second uri) " ")
	     (= flag 0))
	(error "Non deve esserci spazio a inizio fragment!"))
       ((and (= flag 0) (string= (first uri) "#"))
	(get-fragment (cdr uri) 1 fragment))
       ((and (string= (first uri) " ") (not (null (cdr uri)))
	     (= flag 1))
	(get-fragment (cdr uri) 1 (append fragment '(#\% #\2 #\0))))
       ((and (string= (first uri) " ") (null (cdr uri))
	     (= flag 1))
	(error "Il fragment non puo' finire con uno spazio"))
       ((and (null (cdr uri)) (= flag 1))
	(values
	 (coerce (append fragment (cons (car uri) nil)) 'string)
	 nil))
       ((and (not (null (cdr uri))) (= flag 1))
	(get-fragment
	 (cdr uri)
	 1
	 (append fragment (cons (car uri) nil)))))
    ;; else
    (values nil nil)))


;; Queste funzioni restituiscono i vari campi del struct.
(defun uri-scheme (uri) (url-scheme uri))
(defun uri-userinfo (uri) (url-userinfo uri))
(defun uri-host (uri) (url-host uri))
(defun uri-port (uri) (url-port uri))
(defun uri-path (uri) (url-path uri))
(defun uri-query (uri) (url-query uri))
(defun uri-fragment (uri) (url-fragment uri))


;;; -*- end of file -- uri-parse.lisp -*-
