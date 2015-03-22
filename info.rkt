#lang info

(define name "TZInfo")
(define version "0.2")
(define collection "tzinfo")
(define scribblings '(("tzinfo.scrbl" ())))
(define deps (list "base"
                   "rackunit-lib"
                   (list "tzdata" '#:platform 'windows)))
(define build-deps '("racket-doc" "scribble-lib"))
