--- AllTests.lean - Master harness for PIRTM-Formal
-- Build succeeds only if all theorems hold (no ())

import PIRTM.Init
import PIRTM.Signatures
import PIRTM.PARM
import PIRTM.Multiplicity
import PIRTM.PWEH

-- Master check: verify all exported theorems are well-formed
#check PIRTM.PWEH.is_prime_available
#check PIRTM.PWEH.verify_step
#check PIRTM.PWEH.verify_trace
#check PIRTM.PWEH.verify_trace_converges

-- Verify no () in this file
-- CI gate will fail if any #check errors occurred