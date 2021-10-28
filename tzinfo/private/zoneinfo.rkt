#lang racket/base

(require racket/contract/base
         racket/path
         racket/match
         racket/runtime-path
         racket/set
         racket/string
         (for-syntax racket/base))
(require "generics.rkt"
         "structs.rkt"
         "os/unix.rkt"
         "os/windows.rkt"
         "tzfile-parser.rkt"
         "tabfile-parser.rkt"
         "zoneinfo-search.rkt")

(provide (struct-out zoneinfo)
         current-zoneinfo-search-path
         make-zoneinfo-source)

(define (zoneinfo-seconds->tzoffset/utc zi tzid s)
  (define zone (zoneinfo-zone zi tzid))
  (find-utc-offset (zone-intervals zone) s))

(define (zoneinfo-seconds->tzoffset/local zi tzid s)
  (define zone (zoneinfo-zone zi tzid))
  (find-local-offset (zone-intervals zone) s))

(struct zoneinfo
  (dir
   tzids
   zones
   tabzone-index)
  #:transparent
  #:methods gen:tzinfo-source
  [(define seconds->tzoffset/utc   zoneinfo-seconds->tzoffset/utc)
   (define seconds->tzoffset/local zoneinfo-seconds->tzoffset/local)

   (define (tzinfo->all-tzids zi)
     (sort (set->list (zoneinfo-tzids zi))
           string<?))

   (define (tzinfo-has-tzid? zi tzid)
     (set-member? (zoneinfo-tzids zi) tzid))

   (define (tzinfo-tzid->country-codes zi tzid)
     (define tab (hash-ref (zoneinfo-tabzone-index zi) tzid #f))
     (if tab (tabzone-country-codes tab) '()))

   (define (tzinfo-country-code->tzids zi cc)
     (for/list ([tab (in-hash-values (zoneinfo-tabzone-index zi))]
                #:when (member cc (tabzone-country-codes tab)))
       (tabzone-id tab)))

   (define (detect-system-tzid zi)
     (define tests
       (case (system-type)
         [(unix macosx)
          (unix-tzid-tests
           (find-zoneinfo-directory default-zoneinfo-search-path)
           (tzinfo->all-tzids zi))]
         [(windows)
          (windows-tzid-tests)]
         [else
          null]))

     (for*/first ([test (in-list tests)]
                  [candidate (in-value (test))]
                  #:when (tzinfo-has-tzid? zi candidate))
       (string->immutable-string candidate)))])

(define (make-zoneinfo-source)
  (define dir (find-zoneinfo-directory))
  (unless dir (raise-zoneinfo-not-found))

  (zoneinfo dir
            (read-tzids dir)
            (make-hash)
            (parse-tabfile dir)))

(define (raise-zoneinfo-not-found)
  (define (path-string->string ps)
    (if (path? ps)
        (path->string ps)
        ps))

  (raise
   (exn:fail:tzinfo:zoneinfo-not-found
    (apply
     string-append
     `("Unable to locate the zoneinfo database on this computer. "
       "We searched for it in the following places:\n"
       ,@(map (λ (path)
                (string-append "  - " (path-string->string path) "\n"))
              (current-zoneinfo-search-path))
       "\n"
       "Most likely, you need to install a package for your operating "
       "system that contains the zoneinfo database. If the zoneinfo "
       "database is already installed on your computer, please file a "
       "bug report at https://github.com/97jaz/tzinfo/issues and mention "
       "where on your filesystem it is installed."))
    (current-continuation-marks))))

(define (zoneinfo-zone zinfo tzid)
  (hash-ref! (zoneinfo-zones zinfo)
             tzid
             (λ () (build-zone zinfo tzid))))

(define (build-zone zinfo tzid)
  (match (parse-tzfile (zoneinfo-dir zinfo) tzid)
    [(vector intervals offsets)
     (zone tzid intervals offsets)]))

(define default-zoneinfo-search-path
  (list "/usr/share/zoneinfo"
        "/usr/share/lib/zoneinfo"
        "/etc/zoneinfo"))

;; If the tzdata package (ver. >= 0.5) is installed, its zoneinfo
;; directory will be here.
(define-runtime-path tzdata-zoneinfo-path '(share "tzdata/zoneinfo"))

(define current-zoneinfo-search-path
  (make-parameter (cons tzdata-zoneinfo-path default-zoneinfo-search-path)))

(define (find-zoneinfo-directory [path-list (current-zoneinfo-search-path)])
  (for/first ([path (in-list path-list)]
              #:when (valid-zoneinfo-directory? path))
    path))

(define (valid-zoneinfo-directory? path)
  (and (directory-exists? path)
       (ormap file-exists?
              (list (build-path path "zone1970.tab")
                    (build-path path "zone.tab")
                    (build-path path "tab" "zone_sun.tab")))))

(define (read-tzids dir)
  (define (use-path? p)
    (use-relative-path? (find-relative-path dir p)))

  (define (use-relative-path? rel)
    (define rel-str (path->string rel))

    (and (not (regexp-match #rx"\\." rel-str))
         (andmap (λ (f) (not (equal? rel-str f))) EXCLUDED-ZONEINFO-PATHS)))

  (for*/set ([p (in-directory dir use-path?)]
             [r (in-value (find-relative-path dir p))]
             #:when (and (not (directory-exists? p))
                         (use-relative-path? r)))
    (string->immutable-string
     (string-join
      (map path->string (explode-path r))
      "/"))))

(define EXCLUDED-ZONEINFO-PATHS
  '("+VERSION"
    "leapseconds"
    "localtime"
    "posix"
    "posixrules"
    "right"
    "src"
    "tzinstall"
    "Factory"))
