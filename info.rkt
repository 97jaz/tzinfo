#lang info

(define name "TZInfo")
(define version "0.2")
(define collection "tzinfo")
(define deps (list "base"
                   (list "tzdata" '#:platform 'windows)))

(define scribblings '(("tzinfo.scrbl" ())))
