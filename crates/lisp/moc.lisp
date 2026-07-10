;;; MOC Lisp Frontend
;;; Generates terms that can be bridge-parsed into Lean MOC types.

(defpackage :moc
  (:use :cl)
  (:export #:moc-compose
           #:moc-subdivision
           #:moc-accent
           #:moc-rotation
           #:moc-permutation
           #:moc-prime-word))

(in-package :moc)

(defun moc-subdivision (p &optional (r 1))
  (list 'subdivision p r))

(defun moc-accent (d alpha &optional (ch 0))
  (list 'accent d alpha ch))

(defun moc-rotation (d phi)
  (list 'rotation d phi))

(defun moc-permutation (p perm)
  (list 'permutation p perm))

(defmacro moc-compose (&rest ops)
  "Composes MOC operators into a word."
  `(list ,@ops))

(defmacro moc-prime-word (p &key subdivision accent rotation permutation)
  "Constructs a canonical prime word for prime p."
  `(list
    ,@(when subdivision (list `(subdivision ,p ,subdivision)))
    ,@(when accent (list `(accent ,(first accent) ,(second accent))))
    ,@(when rotation (list `(rotation ,(first rotation) ,(second rotation))))
    ,@(when permutation (list `(permutation ,p ,permutation)))))

(defun moc-108-cycle (&key (w0 1.0) (w1 0.8) (w2 0.6) (w3 0.4) (w4 0.2))
  "Generates the standard 108-cycle operator word (ternary-first)."
  (moc-compose
   (moc-subdivision 3 3)
   (moc-subdivision 2 2)
   (moc-accent 27 w0)
   (moc-accent 9 w1)
   (moc-accent 3 w2)
   (moc-accent 4 w3)
   (moc-accent 2 w4)))

;;; Example:
;;; (moc-108-cycle :w0 1.2)
