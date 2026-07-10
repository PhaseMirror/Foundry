const EPSILON = 1e-10;

export function shannonEntropy(probs) {
  return -probs.reduce((sum, p) => {
    if (p <= 0) return sum;
    return sum + p * Math.log2(p);
  }, 0);
}

export function superpositionEntropy(amplitudes) {
  return shannonEntropy(amplitudes.map(a => a.weight));
}

export function klDivergence(p, q) {
  return p.reduce((sum, pi, i) => {
    if (pi <= 0) return sum;
    return sum + pi * Math.log2(pi / Math.max(q[i], EPSILON));
  }, 0);
}

export function crossEntropy(p, q) {
  return -p.reduce((sum, pi, i) => {
    if (pi <= 0) return sum;
    return sum + pi * Math.log2(Math.max(q[i], EPSILON));
  }, 0);
}

export function normalize(weights) {
  const total = weights.reduce((a, b) => a + b, 0);
  if (total <= 0) return weights.map(() => 1 / weights.length);
  return weights.map(w => w / total);
}

export function isWithinEntropyBound(amplitudes, maxEntropy = 6.0) {
  return superpositionEntropy(amplitudes) <= maxEntropy;
}

export function vonNeumannEntropy(eigenvalues) {
  return shannonEntropy(eigenvalues.map(λ => Math.abs(λ)));
}
