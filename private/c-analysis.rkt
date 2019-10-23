#lang racket/base

;; This module is responsible for making sense of strings containing
;; C code, without a parser. Ideally I would use a Clang plugin.

(provide (all-defined-out))

(require racket/list
         racket/string
         "./txexpr.rkt")

(module+ test
  (require rackunit))

(define (cname str)
  (string->symbol (string-append "_" str)))

(define (cnamef fmt-string . args)
  (cname (apply format fmt-string args)))

(define (infer-pointer-depth characters)
  (count (λ (ch) (char=? #\* ch)) characters))

(define (infer-type undecorated-type characters [lookup #hash()])
  (define pointer-depth (infer-pointer-depth characters))

  (define struct?
    (and (hash-has-key? lookup undecorated-type)
         (category=? "struct" (hash-ref lookup undecorated-type))))

  (define (resolve-alias)
    (let ([el (hash-ref lookup undecorated-type)])
      (if (attrs-have-key? el 'alias)
          (attr-ref el 'alias)
          undecorated-type)))
  
  (if struct?
      (cname (case pointer-depth
               [(1)
                (string-append (resolve-alias)
                               "-pointer/null")]
               [(0) (resolve-alias)]
               [else "pointer"]))
      ; Wrap pointer declarations equal to the number of '*'s
      (for/fold ([sig (cname undecorated-type)])
                ([i (in-range pointer-depth)])
        (define ptrtype `(_cpointer/null ,sig))
        (if (member ptrtype '((_cpointer/null _int8) (_cpointer/null _char)))
            '_bytes/nul-terminated
            ptrtype))))

(module+ test
  (test-equal? "No pointers"
               (infer-type "char" '())
               '_char)
  (test-equal? "Depth = 1"
               (infer-type "void" '(#\1 #\* #\f))
               '(_cpointer/null _void))
  (test-equal? "Depth = 2, mixed chars"
               (infer-type "int" '(#\1 #\* #\*))
               '(_cpointer/null (_cpointer/null _int)))
  (test-equal? "Special case: Struct name"
               (infer-type "ST" '() '#hash(("ST" . (type ((category "struct"))))))
               '_ST)
  (test-equal? "Special case: Struct name, Depth = 1"
               (infer-type "ST" '(#\*) '#hash(("ST" . (type ((category "struct"))))))
               '_ST-pointer/null)
  (test-equal? "Special case: Struct name, Depth = 2"
               (infer-type "ST" '(#\* #\*) '#hash(("ST" . (type ((category "struct"))))))
               '_pointer)
  (test-case "Special case: char*"
    (check-equal? (infer-type "char" '(#\*))
                  '_bytes/nul-terminated)
    (check-equal? (infer-type "char" '(#\* #\*))
                 '(_cpointer/null _bytes/nul-terminated))))
