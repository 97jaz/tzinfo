#lang racket/base

(require racket/file
         racket/string
         "env.rkt")

(provide unix-tzid-tests)

(define (unix-tzid-tests default-zoneinfo-dir all-tzids)
  (list tzid-from-env
        (λ () (tzid-from-/etc/localtime default-zoneinfo-dir all-tzids))
        tzid-from-/etc/timezone
        tzid-from-/etc/TIMEZONE
        tzid-from-/etc/sysconfig/clock
        tzid-from-/etc/default/init))

(define /etc/localtime "/etc/localtime")

(define (tzid-from-/etc/localtime default-zoneinfo-dir all-tzids)
  (and
   (file-exists? /etc/localtime)
   default-zoneinfo-dir

   (cond
     [(link-exists? /etc/localtime)
      (tzid-from-linked-/etc/localtime default-zoneinfo-dir all-tzids)]
     [else
      (tzid-from-copied-/etc/localtime default-zoneinfo-dir all-tzids)])))

;; Many unix systems, including the most recent OS X releases, symlink
;; /etc/localtime to a tzinfo file. The file does not contain the tzid;
;; it's merely named by the tzid. So we have to find which of the
;; tzid-named files is identical to /etc/localtime.
(define (tzid-from-linked-/etc/localtime default-zoneinfo-dir all-tzids)
  (define inode (file-or-directory-identity /etc/localtime))
  (define base-path (resolve-path default-zoneinfo-dir))

  (for*/first ([tzid (in-list all-tzids)]
               [f (in-value (build-path base-path tzid))]
               #:when (and (file-exists? f)
                           (= inode (file-or-directory-identity f))))
    tzid))

;; Older versions of OS X, instead of symlinking /etc/localtime to
;; a tzinfo file, copied the file instead. So we can't check
;; for inode identity; instead we need to see if the files have
;; identical contents.
(define (tzid-from-copied-/etc/localtime default-zoneinfo-dir all-tzids)
  (define base-path (resolve-path default-zoneinfo-dir))
  (define size (file-size /etc/localtime))
  (define content (file->bytes /etc/localtime))

  (for*/first ([tzid (in-list all-tzids)]
               [f (in-value (build-path base-path tzid))]
               #:when (and (file-exists? f)
                           (= (file-size f) size)
                           (equal? (file->bytes f) content)))
    tzid))

(define (tzid-from-/etc/timezone)
  (define /etc/timezone "/etc/timezone")

  (and (file-exists? /etc/timezone)
       (string-trim (file->string /etc/timezone))))

(define (tzid-from-/etc/TIMEZONE)
  (define /etc/TIMEZONE "/etc/TIMEZONE")

  (tzid-from-var /etc/TIMEZONE "TZ"))

(define (tzid-from-/etc/sysconfig/clock)
  (define /etc/sysconfig/clock "/etc/sysconfig/clock")

  (tzid-from-var /etc/sysconfig/clock "(?:TIMEZONE|ZONE)"))

(define (tzid-from-/etc/default/init)
  (define /etc/default/init "/etc/default/init")

  (tzid-from-var /etc/default/init "TZ"))

(define (tzid-from-var file var)
  (define re (pregexp (string-append "^\\s*" var "\\s*=\\s*(\\S+)")))

  (and (file-exists? file)
       (for*/last ([s (in-list (file->lines file))]
                   [m (in-value (regexp-match re s))]
                   #:when m)
         (cadr m))))
