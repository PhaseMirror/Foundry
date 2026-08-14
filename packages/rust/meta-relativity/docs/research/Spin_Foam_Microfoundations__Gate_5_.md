                Gate 5: The Complete Causal Chain
                             Ryan O. Van Gelder
               Citizen Gardens / Multiplicity Theory Framework
                                        March 2026

                                              Abstract
         Gate 5 closes the five-gate validation sequence of the CEQG-RG-Langevin pro-
     gramme by establishing an unbroken, unidirectional causal chain from microscopic
     quantum geometry (AL-GFT or Track-B/C variants) through renormalization-group
     flow, stochastic influence functional, and Einstein–Langevin dynamics to the two target
                                                                       eff (CMB scales) and
     late-time observables: the effective local trispectrum amplitude gNL
     the structure-growth parameter S8 (LSS scales). The chain produces the non-tunable
     exponential correlation of Gate 3
                                                                    !
                                                               ∆S8 2
                                                           
                                gNL          1     ∆S8
                          log          =         ·      +O               ,
                                gNL0     c · nNG S8             S8

     without extraneous parameters. With all acceptance criteria from Gates 1–4 satisfied,
     the framework is fully specified, truncation-controlled, and ready for joint Bayesian
     forecasting and confrontation with forthcoming DESI Y5 + LiteBIRD + Euclid data.


1    Requirement Statement
Gate 5 requires demonstration of a complete, modularly validated causal pathway free of
ad-hoc insertions:
                     Microscopic UV boundary conditions (Gate 1)
                                           ↓
                        RG-derived cosmological prior (Gate 2)
                                           ↓
                             Controlled truncation (Gate 4)
                                           ↓
                      Stochastic noise kernel and running vacuum
                                           ↓
                         Modified Einstein–Langevin dynamics
                                           ↓
        Correlated observables ∆gNL and ∆S8 with slope A ∈ [200, 500] (Gate 3).
    The pathway must hold identically across all three tracks (A, B, C). It is mediated
solely by the third cumulant C (3) (from λ6 (k)) and the running-vacuum coefficient ν (from

                                               1
integrated Wetterich flow). The correlation remains falsifiable by its specific exponential
functional form.


2     Expanded Causal Chain
The full pipeline is shown schematically below (each arrow references the responsible gate
and explicit derivation):

               Microscopic UV (AL-GFT / Track B/C)
                 ↓ (Gate 1)
               Noise kernel Nµν + C (3) ∝ λ6 (kCMB )
                 ↓ (Gates 2 & 4)
               RG flow with controlled truncation
                 ↓
               Einstein–Langevin backbone
                 ↓ (Gate 3)
               (∆gNL , ∆S8 ) with exponential correlation slope A ∈ [200, 500]
    Explicit steps (with cross-references):
1. Microscopic foundation (Gate 1, §3): Arithmetic-Langevin GFT (or Track-B
stringy/worldsheet or Track-C inverted multiplicity reconstruction) generates the environ-
mental influence functional. Linear coupling to multiplicity modes produces the leading noise
kernel Nµν and third cumulant C (3) ∝ λ6 (kCMB ).
2. RG flow and prior derivation (Gate 2, §5–6): The sextic truncation of Γk [ϕ]
(melonic + first non-melonic) is evolved via the Wetterich equation from k = MP to k = H0 ,
yielding νeff (M ) with the log-link coefficient c distributed as N (1937, 5442 ) (Gate 2 derived
distribution).
3. Truncation control (Gate 4, §4): Power counting, Ward identities, EPRL asymp-
totics, and ∆c/c < 0.04 error bound ensure higher operators contribute negligibly to nNG
and C (3) .
4. Einstein–Langevin backbone (Gate 1, §5): The noise kernel and running parameters
enter                                                                  
                         Gµν [g] + Λeff (H)gµν = 8πGeff ⟨Tµν ⟩ren + ξµν ,
with Λ(H) = Λ0 + νH 2 and stochastic tensor ξµν having cumulants fixed by the influence
functional.
5. Observable mapping (Gate 3, §2): CMB channel: C (3) (kpivot ) sources tree-level
 eff
gNL  ∼ C (3) /Pζ2 (relative to baseline gNL0 in ΛCDM); LSS channel: ν shifts the growth factor,
producing ∆S8 /S8 ∝ ν · f (kLSS , zeff ). Eliminating the common λ6 (k) running yields the
predicted exponential correlation.


3     Convergence of the Three Tracks
All tracks feed the identical Einstein–Langevin backbone (identical noise kernel statistics
and νeff injection):

                                               2
    • Track A (pure AL-GFT): Zeta-Comb environment.

    • Track B (string-enhanced): Worldsheet βws perturbation (bounded by αws ).

    • Track C (inverted digital twin): Multiplicity cumulant reconstruction via regularized
      inverse problem.

Track-specific corrections remain sub-percent (as bounded in Gate 4) and shift the universal
slope A by less than ∼ 7% relative to the central band.


4     Uniqueness and Falsifiability
The exponential form—locked by logarithmic RG integration of ν versus linear vertex de-
pendence of C (3) —is structurally distinct from linear/power-law shifts in modified-gravity,
neutrino-mass, or dark-energy extensions of ΛCDM. Only the single UV coupling λ6 (k) medi-
ates the link (i.e., no additional parameters can move a point along or off the predicted line).
Detection of a steep positive correlation with slope inside [200, 500] (or null case ∆S8 ≈ 0,
gNL ≲ 104 ) tests the framework directly. Track C serves as an internal consistency check:
reconstruction succeeds only if recovered parameters lie inside the predicted band.


5     Observational Confrontation docs/roadmaps/Roadmap
The framework is now ready for:

    • Joint MCMC sampling over the unified parameter space {M, c, nNG (bounded), track-
      specific nuisance parameters}.

    • Confrontation with forthcoming datasets (DESI Y5, LiteBIRD, Euclid) in the (∆S8 , log gNL )
      plane.

    • Bayesian evidence comparison against ΛCDM and standard extensions.

Current status: All five gates are validated. The framework now stands as a com-
plete, modularly falsifiable pipeline from microscopic quantum geometry (AL-GFT / string-
enhanced / multiplicity-twin reconstructions) to the correlated CMB+LSS observables (∆gNL , ∆S8 ).
The predicted exponential correlation with slope A ∈ [200, 500] is ready for confrontation
with DESI Y5, LiteBIRD, and Euclid.


References
 [1] Daniele Oriti. The group field theory approach to quantum gravity. arXiv preprint,
     2006.

 [2] Aristide Baratin and Daniele Oriti. Group field theory and quantum gravity. Int. J.
     Mod. Phys. A, 26:3415–3436, 2011.

                                               3
 [3] Roberto De Pietri, Laurent Freidel, Kirill Krasnov, and Carlo Rovelli. Barrett–crane
     model from a boulatov–ooguri field theory over a homogeneous space. Nucl. Phys. B,
     574:785–806, 2000.

 [4] Sylvain Carrozza, Daniele Oriti, and Vincent Rivasseau. Renormalization of tensorial
     group field theories: Abelian u(1) models in four dimensions. Commun. Math. Phys.,
     327:603–641, 2014.

 [5] Joseph Ben Geloun. Renormalizable models in rank d ≥ 2 tensorial group field theory.
     Commun. Math. Phys., 332:117–188, 2014.

 [6] Vincent Rivasseau. Random tensors and quantum gravity. Séminaire Poincaré, XXII:1–
     37, 2018.

 [7] Martin Reuter. Nonperturbative evolution equation for quantum gravity. Phys. Rev.
     D, 57:971–985, 1998.

 [8] Frank Saueressig. The functional renormalization group in quantum gravity. Mod. Phys.
     Lett. A, 27:1230012, 2012.

 [9] Roberto Percacci. An introduction to covariant quantum gravity and asymptotic safety.
     World Scientific, 2017.

[10] Joseph Ben Geloun, Riccardo Martini, and Daniele Oriti. Functional renormalization
     group analysis of tensorial group field theories on Rd . Phys. Rev. D, 94:024017, 2016.

[11] Sylvain Carrozza and Vincent Lahoche. Functional renormalization group and tensorial
     group field theory: A new perspective. Class. Quantum Grav., 34:115004, 2017.

[12] Esteban Calzetta and Bei-Lok Hu. Nonequilibrium Quantum Field Theory. Cambridge
     University Press, 2008.

[13] Bei-Lok Hu and Enric Verdaguer. Stochastic gravity: Theory and applications. Living
     Rev. Rel., 7:3, 2004.

[14] Esteban Calzetta, Albert Roura, and Enric Verdaguer. Stochastic description of quan-
     tum gravity. Int. J. Mod. Phys. A, 23:109–118, 2008.

[15] Jonathan Engle, Etera Livine, Roberto Pereira, and Carlo Rovelli. Lqg vertex with
     finite immirzi parameter. Nucl. Phys. B, 799:136–149, 2008.

[16] Carlo Rovelli. Zakopane lectures on loop gravity. PoS QGQGS, 2011:003, 2011.

[17] Planck Collaboration, Y. Akrami, et al. Planck 2018 results. ix. constraints on primor-
     dial non-gaussianity. Astron. Astrophys., 641:A9, 2020.

[18] P. A. R. Ade and others (Planck Collaboration). Planck 2015 results. xvii. constraints
     on primordial non-gaussianity. Astron. Astrophys., 594:A17, 2016.



                                             4
[19] DESI Collaboration, A. G. Adame, et al. Desi 2024 vi: Cosmological constraints from
     the measurements of baryon acoustic oscillations. arXiv preprint, 2024.

[20] M. Asgari and others (KiDS Collaboration). Kids-1000 cosmology: Cosmic shear con-
     straints and comparison between two point statistics. Astron. Astrophys., 645:A104,
     2021.

[21] Joan Solà. Cosmological constant and vacuum energy: old and new ideas. J. Phys.
     Conf. Ser., 453:012015, 2013.

[22] Joan Solà Peracaula, Adrià Gómez-Valent, Javier de Cruz Pérez, and Cristian Moreno-
     Pulido. Running vacuum in quantum field theory: A new perspective on the cosmolog-
     ical constant problem. Class. Quantum Grav., 36:245001, 2019.

[23] Joseph Ben Geloun, Riccardo Martini, and Daniele Oriti. Towards a renormalization
     group approach to gft cosmology. Universe, 7:302, 2021.

[24] Daniele Oriti, Lorenzo Sindoni, and Edward Wilson-Ewing. Emergent friedmann dy-
     namics from a group field theory condensate. Class. Quantum Grav., 34:04LT01, 2017.




                                             5
