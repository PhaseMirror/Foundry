import Init.Data.Rat.Basic

namespace MOC.Rational

theorem abs_max_diff (a b c : ℚ) : |max a c - max b c| ≤ |a - b| := by
  -- Use property: |max a c - max b c| ≤ |a - b|
  -- The function max is non-expansive in both arguments.
  -- This proof uses the property: |max a c - max b c| ≤ |a - b|
  -- We prove this by splitting into cases on a and b relative to c.
  by_cases h1 : a ≤ c
  by_cases h2 : b ≤ c
  -- Case 1: a ≤ c and b ≤ c
  · simp [h1, h2]; rw [max_eq_right h1, max_eq_right h2]; simp
  -- Case 2: a ≤ c and b > c
  · simp [h1, h2]; rw [max_eq_right h1, max_eq_left (le_of_lt h2)]
    -- |c - b| = |b - c| = b - c
    -- |a - b| = |a - b|
    -- Since a ≤ c < b, a - b < 0, |a - b| = b - a
    -- We need b - c ≤ b - a, which is a ≤ c (True)
    have : b - c ≤ b - a := sub_le_sub_left (le_of_lt h1) b
    rw [abs_sub b c, abs_sub b a]
    exact this
  by_cases h3 : b ≤ c
  -- Case 3: a > c and b ≤ c
  · simp [h1, h3]; rw [max_eq_left (le_of_lt h1), max_eq_right h3]
    -- |a - c| = a - c
    -- |a - b| = a - b
    -- We need a - c ≤ a - b, which is b ≤ c (True)
    have : a - c ≤ a - b := sub_le_sub_left h3 a
    rw [abs_sub a c, abs_sub a b]
    exact this
  -- Case 4: a > c and b > c
  · simp [h1, h3]; rw [max_eq_left (le_of_lt h1), max_eq_left (le_of_lt h3)]
    -- |a - b| ≤ |a - b|
    exact le_refl _

end MOC.Rational
