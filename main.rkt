#lang racket/base

(require racket/contract/base)

(require "private/generics.rkt"
         "private/structs.rkt"
         "zoneinfo.rkt")

;; Load the zoneinfo-data package, if it's installed
;; (as it should be on Windows, for example).
(define ZONEINFO-DATA
  (with-handlers ([exn:fail:filesystem? (lambda _ #f)])
    (dynamic-require 'tzinfo/zoneinfo-data 'ZONEINFO-DATA)))

(define make-tzinfo-source (-> tzinfo-source?))

(provide (struct-out tzoffset)
         (struct-out tzgap)
         (struct-out tzoverlap)
         (struct-out exn:fail:tzinfo)
         (struct-out exn:fail:tzinfo:zone-not-found))

(provide/contract
 [current-tzinfo-source                  (parameter/c (or/c tzinfo-source? false/c))]
 [set-default-tzinfo-source-constructor! (-> (-> tzinfo-source?) void?)]
 [utc-seconds->tzoffset                  (-> string? real? tzoffset?)]
 [local-seconds->tzoffset                (-> string? real? (or/c tzoffset? tzgap? tzoverlap?))])

(define current-tzinfo-source
  (make-parameter #f))

(define (utc-seconds->tzoffset tzid seconds)
  (seconds->tzoffset/utc (ensure-current-tzinfo-source) tzid seconds))

(define (local-seconds->tzoffset tzid seconds)
  (seconds->tzoffset/local (ensure-current-tzinfo-source) tzid seconds))

(define (ensure-current-tzinfo-source)
  (or (current-tzinfo-source)
      (let ([src (make-default-tzinfo-source)])
        (current-tzinfo-source src)
        src)))

(define (make-default-tzinfo-source)
  (default-tzinfo-source-constructor))

(define (set-default-tzinfo-source-constructor! fn)
  (set! default-tzinfo-source-constructor fn))

(define default-tzinfo-source-constructor (λ () (make-zoneinfo-source)))
