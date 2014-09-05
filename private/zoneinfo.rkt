#lang racket/base

(require racket/contract/base
         racket/path
         racket/match)
(require "generics.rkt"
         "structs.rkt"
         "tzfile-parser.rkt"
         "zoneinfo-search.rkt")

(provide current-zoneinfo-search-path
         make-zoneinfo-source)

(define (zoneinfo-seconds->tzoffset/utc zi tzid s)
  (define zone (zoneinfo-zone zi tzid))
  (find-utc-offset (zone-intervals zone) s))

(define (zoneinfo-seconds->tzoffset/local zi tzid s)
  (define zone (zoneinfo-zone zi tzid))
  (find-local-offset (zone-intervals zone) s))

(struct zoneinfo
  (dir
   zones)
  #:transparent
  #:methods gen:tzinfo-source
  [(define seconds->tzoffset/utc   zoneinfo-seconds->tzoffset/utc)
   (define seconds->tzoffset/local zoneinfo-seconds->tzoffset/local)])

(define (make-zoneinfo-source)
  (zoneinfo (find-zoneinfo-directory)
            (make-hash)))
   
(define (zoneinfo-zone zinfo tzid)
  (hash-ref! (zoneinfo-zones zinfo)
             tzid
             (λ () (build-zone zinfo tzid))))

(define (build-zone zinfo tzid)
  (match (parse-tzfile (zoneinfo-dir zinfo) tzid)
    [(vector intervals offsets)
     (zone tzid intervals offsets)]))

(define current-zoneinfo-search-path
  (make-parameter (list "/usr/share/zoneinfo"
                        "/usr/share/lib/zoneinfo"
                        "/etc/zoneinfo")))

(define (find-zoneinfo-directory)
  (for/first ([path (in-list (current-zoneinfo-search-path))]
              #:when (valid-zoneinfo-directory? path))
    path))

(define (valid-zoneinfo-directory? path)
  (and (directory-exists? path)
       (ormap file-exists? 
              (list (build-path path "zone1970.tab")
                    (build-path path "zone.tab")
                    (build-path path "tab" "zone_sun.tab")))))

(define (read-tzids dir)
  (for/list ([p (in-directory dir)]
             #:unless (excluded-zoneinfo-path? p))
    (path->string (find-relative-path dir p))))
 
(define (excluded-zoneinfo-path? path)
  (or (directory-exists? path)
      (let ([filename (path->string (file-name-from-path path))])
        (or (regexp-match? #px"\\." filename)
            (member filename
                    '("+VERSION" "localtime" "posix" "posixrules" "right" "src" "Factory"))))))

