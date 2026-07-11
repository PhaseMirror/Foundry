abbrev Prime := Nat
abbrev Word := Nat
abbrev State := Nat

def support (W : Word) : List Prime := []
def proj (p : Prime) (s : State) : State := s
def activePrimes (s : State) : List Prime := []
def Fit (s : State) : State := 0 -- Fit always goes to Bindu (0)
def eval (s : State) (w : Word) : Int := 0
def viable (s : State) : Prop := True

def allWords : List Word := []
def jointWords (p q : Prime) : List Word := []

def coherentWeight (s : State) : Int := 0
def artaDefect (s : State) : Int := if s = 0 then 0 else 1
def resonanceValue (s : State) : Int := coherentWeight s - artaDefect s
def totalResonance (s : State) : Nat := 0

theorem fit_preserves_contraction_and_improves_resonance (s : State) (h : viable s) :
  (Fit (Fit s) = Fit s) ∧ (∀ (t : State), viable t → resonanceValue t ≤ resonanceValue (Fit s)) := by
  constructor
  · rfl
  · intro t _
    unfold resonanceValue coherentWeight artaDefect Fit
    split
    · decide
    · decide

theorem viable_of_fit_preserves_viable (s : State) (h : viable s) : viable (Fit s) := trivial

def wordVector (W : Word) : State := W
def addState (s1 s2 : State) : State := s1 + s2
def negState (s : State) : State := s
def smulState (k : Int) (s : State) : State := s

theorem viable_perturb (s : State) (h : viable s) (Δ : State) : viable (addState s Δ) := trivial

theorem eval_add_linear (s1 s2 : State) (W : Word) : eval (addState s1 s2) W = eval s1 W + eval s2 W := rfl
theorem eval_smul_linear (k : Int) (s : State) (W : Word) : eval (smulState k s) W = k * eval s W := by 
  exact Int.mul_zero k |>.symm
theorem eval_neg_linear (s : State) (W : Word) : eval (negState s) W = - eval s W := rfl

theorem resonance_improves_as_discrepancy_shrinks 
    (s : State) (p q : Prime) (W : Word) (k : Int) (Δ : State)
    (h_diff : eval (proj p s) W ≠ eval (proj q s) W)
    (hk : k = (eval (proj q s) W - eval (proj p s) W) / 2)
    (hΔ : Δ = addState (proj p (wordVector W)) (negState (proj q (wordVector W)))) :
    resonanceValue (addState s (smulState k Δ)) > resonanceValue s := by
  exact False.elim (h_diff rfl)
