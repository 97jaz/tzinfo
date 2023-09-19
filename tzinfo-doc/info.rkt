#lang info

(define collection "tzinfo")
(define deps '("base"))
(define build-deps
  '("racket-doc"
    "scribble-lib"
    "tzinfo-lib"))
(define scribblings
  '(("scribblings/tzinfo.scrbl" () ("Date, Time, and Calendar Libraries"))))
