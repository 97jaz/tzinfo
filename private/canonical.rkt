#lang racket/base

(require racket/match
         racket/runtime-path)

(provide canonical-tzid)

(define-runtime-path data-dir "data")

(define (canonical-tzid id)
  (hash-ref (canon-hash) id #f))


(define (canon-hash)
  (unless CANON
    (set! CANON (build-canon-hash)))
  
  CANON)

(define (build-canon-hash)
  (define path (build-path data-dir "backward"))
  
  (call-with-input-file* path
    (λ (in)
      (for*/hash ([l (in-lines in)]
                  [xs (in-value (regexp-match #px"^Link\\s+([^\\s]+)\\s+([^\\s]+)" l))]
                  #:when xs)
        (match-define (list _ canon alias) xs)
        (values alias canon)))))

(define CANON #f)