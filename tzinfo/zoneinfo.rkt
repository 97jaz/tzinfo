#lang racket/base

(require racket/contract/base
         racket/match
         racket/runtime-path
         setup/getinfo
         (for-syntax racket/base
                     racket/match
                     setup/getinfo))
(require "private/generics.rkt"
         "private/zoneinfo.rkt")

(provide/contract
 [current-zoneinfo-search-path (parameter/c (listof path-string?))]
 [make-zoneinfo-source         (-> tzinfo-source?)])


;; If the tzdata package is installed, put its zoneinfo directory at
;; the head of the search path.
(define-runtime-path-list tzdata-paths
  (match (find-relevant-directories '(tzdata-zoneinfo-module-path))
    [(cons info-dir _)
     (define path ((get-info/full info-dir) 'tzdata-zoneinfo-module-path))
     (list path)]
    [_
     null]))

(match tzdata-paths
  [(cons dir _)
   (current-zoneinfo-search-path
    (cons dir (current-zoneinfo-search-path)))]
  [_
   (void)])
