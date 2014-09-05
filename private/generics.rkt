#lang racket/base

(require racket/generic)

(provide (all-defined-out))

(define-generics tzinfo-source
  (seconds->tzoffset/utc    tzinfo-source tzid seconds)
  (seconds->tzoffset/local  tzinfo-source tzid seconds))
