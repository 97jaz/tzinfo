#lang racket/base

(require racket/file
         racket/match
         racket/path
         racket/string
         "env.rkt")

(provide detect-tzid/unix)

(define (detect-tzid/unix zoneinfo-dir)
  (or (tzid-from-env)
      (and zoneinfo-dir
           (tzid-from-/etc/localtime zoneinfo-dir))
      (tzid-from-/etc/timezone)
      (tzid-from-/etc/TIMEZONE)
      (tzid-from-/etc/sysconfig/clock)
      (tzid-from-/etc/default/init)))


(define (tzid-from-/etc/localtime zoneinfo-dir)
  (define /etc/localtime "/etc/localtime")
  (define base-path (resolve-path zoneinfo-dir))
  
  (define (find-matching-zone)
    (define size (file-size /etc/localtime))
    (define content (file->bytes /etc/localtime))
    
    (for/first ([f (in-directory base-path)]
                #:when (and (file-exists? f)
                            (= (file-size f) size)
                            (equal? (file->bytes f) content)))
      (path->string (find-relative-path base-path f))))
  
  (and (file-exists? /etc/localtime)
       (let ([rel (find-relative-path base-path (resolve-path /etc/localtime))])
         (match (explode-path rel)
           [(cons 'up _) (find-matching-zone)]
           [_ (path->string rel)]))))

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
