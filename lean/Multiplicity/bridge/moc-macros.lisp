;; Lisp-like MOC macro expansion
(defmacro moc-108-cycle ()
  '(MOC.OperatorWord.mk [ (MOC.PrimeOp.sub 3 3) 
                          (MOC.PrimeOp.sub 3 3) 
                          (MOC.PrimeOp.sub 3 3) 
                          (MOC.PrimeOp.sub 2 2) 
                          (MOC.PrimeOp.sub 2 2) ]))
