import Foundations.Recursive.Core
import Foundations.Recursive.FixedPoint
import Foundations.Recursive.Induction
import Foundations.Recursive.Coinduction
import Foundations.Recursive.WellFounded
import Foundations.Recursive.Examples

/-!
# Recursive Foundations Test Suite

Verifies all core theorems and definitions compile correctly.
-/

namespace Tests.Recursive

/-! ## Core Tests -/

#check @Foundations.Recursive.Core.PNat.add
#check @Foundations.Recursive.Core.PNat.mul
#check @Foundations.Recursive.Core.PNat.le
#check @Foundations.Recursive.Core.PNat.add_zero
#check @Foundations.Recursive.Core.PNat.add_succ
#check @Foundations.Recursive.Core.PNat.mul_zero
#check @Foundations.Recursive.Core.PNat.mul_succ
#check @Foundations.Recursive.Core.PNat.le_refl
#check @Foundations.Recursive.Core.PNat.le_trans

#check @Foundations.Recursive.Core.PList.append
#check @Foundations.Recursive.Core.PList.length
#check @Foundations.Recursive.Core.PList.map
#check @Foundations.Recursive.Core.PList.append_nil
#check @Foundations.Recursive.Core.PList.append_assoc
#check @Foundations.Recursive.Core.PList.map_id
#check @Foundations.Recursive.Core.PList.length_map

#check @Foundations.Recursive.Core.PTree.size
#check @Foundations.Recursive.Core.PTree.depth
#check @Foundations.Recursive.Core.PTree.map
#check @Foundations.Recursive.Core.PTree.size_leaf
#check @Foundations.Recursive.Core.PTree.size_node
#check @Foundations.Recursive.Core.PTree.map_id
#check @Foundations.Recursive.Core.PTree.size_map

/-! ## Fixed Point Tests -/

#check @Foundations.Recursive.FixedPoint.IsFixedPoint
#check @Foundations.Recursive.FixedPoint.Y
#check @Foundations.Recursive.FixedPoint.fact
#check @Foundations.Recursive.FixedPoint.fib
#check @Foundations.Recursive.FixedPoint.fact_zero
#check @Foundations.Recursive.FixedPoint.fact_succ
#check @Foundations.Recursive.FixedPoint.fib_zero
#check @Foundations.Recursive.FixedPoint.fib_succ_succ

/-! ## Induction Tests -/

#check @Foundations.Recursive.Induction.pnat_ind
#check @Foundations.Recursive.Induction.plist_ind
#check @Foundations.Recursive.Induction.ptree_ind
#check @Foundations.Recursive.Induction.strong_pnat_ind
#check @Foundations.Recursive.Induction.complete_ind
#check @Foundations.Recursive.Induction.double_pnat_ind
#check @Foundations.Recursive.Induction.add_assoc
#check @Foundations.Recursive.Induction.even_or_odd

/-! ## Coinduction Tests -/

#check @Foundations.Recursive.Coinduction.PStream
#check @Foundations.Recursive.Coinduction.PStream.head
#check @Foundations.Recursive.Coinduction.PStream.tail
#check @Foundations.Recursive.Coinduction.PStream.map
#check @Foundations.Recursive.Coinduction.ones
#check @Foundations.Recursive.Coinduction.from
#check @Foundations.Recursive.Coinduction.nats
#check @Foundations.Recursive.Coinduction.fibStream
#check @Foundations.Recursive.Coinduction.ones_take
#check @Foundations.Recursive.Coinduction.from_head
#check @Foundations.Recursive.Coinduction.from_tail
#check @Foundations.Recursive.Coinduction.fibStream_head

/-! ## Well-Founded Tests -/

#check @Foundations.Recursive.WellFounded.Acc
#check @Foundations.Recursive.WellFounded.WellFounded
#check @Foundations.Recursive.WellFounded.well_founded_ind
#check @Foundations.Recursive.WellFounded.well_founded_rec
#check @Foundations.Recursive.WellFounded.lt_wf
#check @Foundations.Recursive.WellFounded.lex_wf
#check @Foundations.Recursive.WellFounded.ackermann_wf

/-! ## Examples Tests -/

#check @Foundations.Recursive.Examples.fact
#check @Foundations.Recursive.Examples.fib
#check @Foundations.Recursive.Examples.gcd
#check @Foundations.Recursive.Examples.reverse
#check @Foundations.Recursive.Examples.filter
#check @Foundations.Recursive.Examples.inorder
#check @Foundations.Recursive.Examples.mirror
#check @Foundations.Recursive.Examples.even_mut
#check @Foundations.Recursive.Examples.odd_mut
#check @Foundations.Recursive.Examples.fact_zero
#check @Foundations.Recursive.Examples.fact_succ
#check @Foundations.Recursive.Examples.fib_zero
#check @Foundations.Recursive.Examples.fib_one
#check @Foundations.Recursive.Examples.reverse_nil
#check @Foundations.Recursive.Examples.reverse_cons
#check @Foundations.Recursive.Examples.length_reverse
#check @Foundations.Recursive.Examples.reverse_reverse
#check @Foundations.Recursive.Examples.mirror_mirror
#check @Foundations.Recursive.Examples.size_mirror

end Tests.Recursive
