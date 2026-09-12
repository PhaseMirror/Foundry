use super::term::{Term, MAX_TERMS};

pub struct UnionFind {
    pub parent: [usize; MAX_TERMS],
    pub rank: [u8; MAX_TERMS],
    pub terms: [Option<Term>; MAX_TERMS],
    pub size: usize,
}

impl UnionFind {
    pub fn new() -> Self {
        let mut uf = Self {
            parent: [0; MAX_TERMS],
            rank: [0; MAX_TERMS],
            terms: [None; MAX_TERMS],
            size: 0,
        };
        for i in 0..MAX_TERMS {
            uf.parent[i] = i;
        }
        uf
    }

    /// Find with path compression.
    pub fn find(&mut self, x: usize) -> usize {
        let mut root = x;
        while root != self.parent[root] {
            root = self.parent[root];
        }
        let mut curr = x;
        while curr != root {
            let nxt = self.parent[curr];
            self.parent[curr] = root;
            curr = nxt;
        }
        root
    }

    /// Union by rank. Returns true if a merge occurred.
    pub fn union(&mut self, a: usize, b: usize) -> bool {
        let ra = self.find(a);
        let rb = self.find(b);
        if ra == rb {
            return false;
        }
        if self.rank[ra] < self.rank[rb] {
            self.parent[ra] = rb;
        } else if self.rank[ra] > self.rank[rb] {
            self.parent[rb] = ra;
        } else {
            self.parent[rb] = ra;
            self.rank[ra] += 1;
        }
        true
    }

    /// Get or create a term node. Returns its index.
    pub fn get_or_create(&mut self, term: Term) -> usize {
        for i in 0..self.size {
            if let Some(t) = &self.terms[i] {
                if *t == term {
                    return i;
                }
            }
        }
        self.add_node(term)
    }

    /// Add a new term node. Returns its index.
    pub fn add_node(&mut self, term: Term) -> usize {
        if self.size >= MAX_TERMS {
            return MAX_TERMS;
        }
        let idx = self.size;
        self.terms[idx] = Some(term);
        self.parent[idx] = idx;
        self.rank[idx] = 0;
        self.size += 1;
        idx
    }

    /// Find the index of an existing term.
    pub fn get_index(&self, term: Term) -> usize {
        for i in 0..self.size {
            if let Some(t) = &self.terms[i] {
                if *t == term {
                    return i;
                }
            }
        }
        MAX_TERMS
    }

    /// Check if two terms are in the same equivalence class.
    pub fn equivalent(&mut self, a: usize, b: usize) -> bool {
        self.find(a) == self.find(b)
    }

    /// Get the root representative of an index.
    pub fn root_of(&mut self, x: usize) -> usize {
        self.find(x)
    }

    /// Count the number of equivalence classes.
    pub fn num_classes(&mut self) -> usize {
        let mut roots = [false; MAX_TERMS];
        for i in 0..self.size {
            roots[self.find(i)] = true;
        }
        roots.iter().filter(|&&r| r).count()
    }

    /// Compact representation: reassign indices to roots.
    pub fn compact(&mut self) {
        let mut root_map = [usize::MAX; MAX_TERMS];
        let mut next_id = 0;
        for i in 0..self.size {
            let r = self.find(i);
            if root_map[r] == usize::MAX {
                root_map[r] = next_id;
                next_id += 1;
            }
        }
        for i in 0..self.size {
            self.parent[i] = root_map[self.find(i)];
        }
    }

    /// Verify: if a ~ b, then Close(a) ~ Close(b) for all a, b.
    /// This is the congruence closure property that Kani must discharge.
    pub fn is_congruence_closed(&mut self) -> bool {
        for i in 0..self.size {
            for j in 0..self.size {
                if self.find(i) == self.find(j) {
                    let ci = self.get_or_create(Term::Close(i as u8));
                    let cj = self.get_or_create(Term::Close(j as u8));
                    if self.find(ci) != self.find(cj) {
                        return false;
                    }
                }
            }
        }
        true
    }

    /// Verify: all defined compositions and closures are equated.
    /// If compose_p(x,y) = some(z), then Comp(x,y) ~ z.
    /// If closure_p(x) = some(y), then Close(x) ~ y.
    pub fn preserves_defined_ops(
        &mut self,
        comp_def: &[(u8, u8, Option<u8>); MAX_TERMS],
        close_def: &[(u8, Option<u8>); MAX_TERMS],
    ) -> bool {
        for &(x, y, z_opt) in comp_def.iter() {
            if let Some(z) = z_opt {
                let idx_xy = self.get_or_create(Term::Comp(x, y));
                let idx_z = self.get_or_create(Term::Var(z));
                if self.find(idx_xy) != self.find(idx_z) {
                    return false;
                }
            }
        }
        for &(x, y_opt) in close_def.iter() {
            if let Some(y) = y_opt {
                let idx_close = self.get_or_create(Term::Close(x));
                let idx_y = self.get_or_create(Term::Var(y));
                if self.find(idx_close) != self.find(idx_y) {
                    return false;
                }
            }
        }
        true
    }

    /// Verify: composition respects equivalence classes.
    /// If a ~ b and c ~ d, then Comp(a,c) ~ Comp(b,d).
    pub fn composition_respects_congruence(&mut self) -> bool {
        for i in 0..self.size {
            for j in 0..self.size {
                if self.find(i) == self.find(j) {
                    for k in 0..self.size {
                        let cik = self.get_or_create(Term::Comp(i as u8, k as u8));
                        let cjk = self.get_or_create(Term::Comp(j as u8, k as u8));
                        if self.find(cik) != self.find(cjk) {
                            return false;
                        }
                        let cki = self.get_or_create(Term::Comp(k as u8, i as u8));
                        let ckj = self.get_or_create(Term::Comp(k as u8, j as u8));
                        if self.find(cki) != self.find(ckj) {
                            return false;
                        }
                    }
                }
            }
        }
        true
    }
}
