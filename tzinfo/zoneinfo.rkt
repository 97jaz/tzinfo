#lang racket/base

(require racket/contract/base
         racket/runtime-path
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
(define-syntax (detect-tzdata stx)
  (syntax-case stx ()
    [(_)
     (match (find-relevant-directories '(tzdata-zoneinfo-module-path))
       [(cons info-dir _)
        (let ([path ((get-info/full info-dir) 'tzdata-zoneinfo-module-path)])
          #`(begin
              (define-runtime-path tzdata-path '#,path)
              (current-zoneinfo-search-path
               (cons (simplify-path tzdata-path)
                     (current-zoneinfo-search-path)))))]
       [_ #'(void)])]))

(detect-tzdata)
