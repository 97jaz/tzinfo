#lang racket/base

(require racket/contract/base
         racket/match
         setup/getinfo)
(require "private/generics.rkt"
         "private/zoneinfo.rkt")

(provide/contract
 [current-zoneinfo-search-path (parameter/c (listof path-string?))]
 [make-zoneinfo-source         (-> tzinfo-source?)])


;; If the tzdata package is installed, put its zoneinfo directory at
;; the head of the search path.
(match (find-relevant-directories '(tzdata-zoneinfo-dir))
  [(? pair?)
   (define tzdata-zoneinfo-dir
     (simplify-path (dynamic-require 'tzinfo/tzdata 'tzdata-zoneinfo-dir)))

   (current-zoneinfo-search-path
    (cons tzdata-zoneinfo-dir
          (current-zoneinfo-search-path)))]
  [_ (void)])
