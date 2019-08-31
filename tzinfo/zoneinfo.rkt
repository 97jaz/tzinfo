#lang racket/base

(require racket/contract/base
         racket/match
         racket/runtime-path
         setup/getinfo
         (for-syntax racket/base
                     racket/match
                     setup/getinfo))
(require "private/generics.rkt"
         "private/zoneinfo.rkt"
         (for-syntax "private/zoneinfo.rkt"))

(provide/contract
 [current-zoneinfo-search-path (parameter/c (listof path-string?))]
 [make-zoneinfo-source         (-> tzinfo-source?)])


;; Use the zoneinfo database from the tzdata package, if it's installed (as it
;; should be on Windows, for example).  This is accomplished in three steps:

;; Define a runtime path list with the 'tzdata-zoneinfo-dir (defined in the
;; info file for the tzdata package) which points to the time zone information
;; files from the tzdata package.  This runtime path list will ensure that the
;; relevant files are copied into the distribution by "raco dist", but inside
;; a distribution build, this path list will be empty as the tzdata module can
;; no longer be resolved.  This is not a problem, as the files have been
;; already copied into the distribution.
;;
;; We use a runtime path list instead of a runtime path, so we can have an
;; empty list on non Windows OS-es, where timezone files are part of the
;; system.
;;
(define-runtime-path-list tzdata-path
  (match (find-relevant-directories '(tzdata-zoneinfo-dir))
    [(cons dir _)
     (define relpath ((get-info/full dir) 'tzdata-zoneinfo-dir))
     (list (build-path dir relpath))]
    [_ '()]))

;; Define a runtime path to the "zone.tab" file.  At runtime, this path will
;; be adjusted to point to the "zone.tab" file inside the distribution build.
;; Note that we cannot use just the directory here, "tzinfo/private/data", as
;; the module name resolver will not look at the last element, "data", and the
;; actual path found would depend on the order in which the "tzinfo" and
;; "tzdata" packages are listed in the "links.rktd" file, as the path
;; "tzinfo/private" is defined in both.
;;
;; We use a runtime path list instead of a runtime path, so we can have an
;; empty list on non Windows OS-es, where timezone files are part of the
;; system.
(define-runtime-path-list zone-tab-file
  (if (eq? (system-type) 'windows)
      '((lib "tzinfo/private/data/zone.tab"))
      '()))

;; Setup the zoneinfo search path from the zone-tab-file, if it is defined.
(unless (null? zone-tab-file)
  (current-zoneinfo-search-path
   (for/list ([p (in-list zone-tab-file)])
     (define-values (base name dir?) (split-path p))
     base)))
