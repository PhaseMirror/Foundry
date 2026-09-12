import re

with open("lean/Multiplicity/Prime.lean", "r") as f:
    content = f.read()

# Fix PrimeFactor structure by removing hPrime
content = re.sub(r'hPrime : IsPrime prime\n', '', content)
content = re.sub(r'\(by decide\)', '', content)
content = re.sub(r'PrimeFactor\.mk (\w+) (\d+)', r'PrimeFactor.mk \1 \2', content)

# Fix generate type signature
content = content.replace("generate (count found current : Nat)", "generate (count : Nat) (found : List Nat) (current : Nat)")

# Fix fuel in count and factorize
content = content.replace(
    "let rec count (p m acc : Nat) : Nat :=",
    "let rec count (p m acc fuel : Nat) : Nat :=\n      match fuel with | 0 => acc | f + 1 =>"
)
content = content.replace("if m % p = 0 then count p (m / p) (acc + 1) else acc", "if m % p = 0 then count p (m / p) (acc + 1) f else acc")
content = content.replace("let exp = count p m 0", "let exp := count p m 0 m")

content = content.replace(
    "let rec factorize (m : Nat) (p : Nat) (acc : List PrimeFactor) : List PrimeFactor :=",
    "let rec factorize (m p fuel : Nat) (acc : List PrimeFactor) : List PrimeFactor :=\n      match fuel with | 0 => acc | f + 1 =>"
)
content = content.replace("factorize (m / (p ^ exp)) (p + 1) (acc", "factorize (m / (p ^ exp)) (p + 1) f (acc")
content = content.replace("factorize m (p + 1) acc", "factorize m (p + 1) f acc")
content = content.replace("factorize n 2 []", "factorize n 2 n []")

# Add List operations
list_ops = """
def List.bind {α β : Type u} (l : List α) (f : α → List β) : List β :=
  l.foldr (fun a acc => f a ++ acc) []

def List.eraseDuplicates [BEq α] : List α → List α
  | [] => []
  | a::as => a :: (as.eraseDuplicates.filter (fun x => !(x == a)))

"""
content = content.replace("namespace Multiplicity.Prime\n", "namespace Multiplicity.Prime\n" + list_ops)

# Fix derivation of Inhabited PrimeFactor
content = content.replace("deriving Repr, BEq", "deriving Repr, BEq, Inhabited")

with open("lean/Multiplicity/Prime.lean", "w") as f:
    f.write(content)
