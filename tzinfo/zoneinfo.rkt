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


;; Use the zoneinfo database from the tzdata package, if it's installed
;; (as it should be on Windows, for example).
(define-runtime-path-list tzdata-paths
  (match (find-relevant-directories '(tzdata-zoneinfo-dir))
    [(cons dir _)
     (define relpath ((get-info/full dir) 'tzdata-zoneinfo-dir))
     (define zoneinfo-dir (build-path dir relpath))

     (current-zoneinfo-search-path (list zoneinfo-dir))
     
     (parameterize ([current-directory zoneinfo-dir])
       (for/list ([f (in-directory)])
         (list 'lib (path->string (build-path "tzinfo" relpath (path->string f))))))]
    [_ '()]))
