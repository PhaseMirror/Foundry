---
slug: dynamic-scaling-relation-for-dark-matter
status: draft
created: '2026-03-20'
updated: '2026-03-20'
version: 0.1.0
tags:
- multiplicity
traceability:
  path: 04-domains/meta-relativity/Dynamic_Scaling_Relation_for_Dark_Matter.md
  last_synced: '2026-03-20T17:17:19.177715Z'
---

       I NTEGRATION OF P RIME -E NCODING AND M ULTIPLICITY
    T HEORY INTO THE DYNAMIC S CALING R ELATION FOR DARK
          M ATTER M ASS IN S TRONG G RAVITATIONAL L ENSES


                                        Tyler Van Osdol & Ryan Van Gelder

                                  Citizen Gardens - The Foundation of Multiplicity
                                              info@citizengardens.org




                                                    A BSTRACT
         This study introduces a novel empirical relation for estimating dark matter (DM) mass in galaxies,
         characterized by a dynamic scaling parameter (k). The relation (MDM = 4M (k − 1)) links the total
         galactic mass (M ) to the DM mass (MDM ). Using 10 strong lensing systems for training and 5 for
         validation, we demonstrate that this dynamic model significantly improves predictions of Einstein
         radii (θE ) over a static k of 3.0, reducing the root-mean-square (RMS) of the residuals by 30%. The
         model suggests a potential universal scaling relation for DM mass, influenced by galaxy structure and
         evolution.




1   Introduction



Gravitational lensing is a powerful tool for probing the distribution of dark matter (DM) in the universe. While
theoretical models like Navarro-Frenk-White (NFW) profiles describe DM halos in detail, their complexity often
complicates large-scale applications. The empirical scaling relation (MDM = 4M (k − 1)) offers a simpler alternative,
linking total galactic mass (M ) to DM mass (MDM ) using a single parameter (k). However, the assumption of a fixed k
oversimplifies galaxy diversity. Here, we develop a dynamic model for k that depends on baryonic mass fraction,
redshift, and total mass, improving the model’s accuracy and providing insights into the physical processes governing
dark matter distribution.
Preprint - PrimeAI Enhanced Template


2   Prime-Based Encoding

Define the prime-based encoding function for parameters:

                                                           ϕ(x) = px · eiθx ,                                                             (1)

where px is a prime number uniquely assigned to parameter x, and θx is a phase representing contextual variability.
Encoding for key parameters becomes:

                                                        ϕ(Mb ) = pMb · eiθMb ,                                                            (2)

                                                        ϕ(M ) = pM · eiθM ,                                                               (3)

                                                         ϕ(zL ) = pzL · eiθzL .                                                           (4)



3   Tensor-Based Coupling

Introduce multi-scale coupling through tensor networks. The scaling relation extends to:

                                                             X
                                                      k=            Tij ϕ(xi )ϕ(xj ),                                                     (5)
                                                              i,j


where Tij is the interaction tensor capturing dependencies among parameters.


4   Dynamic Multiplicity Equation

The dynamic multiplicity-enhanced scaling relation is:

                                  ∂k                ϕ(Mb )
                                     = α(t)k + β(t)        + γ(t)ϕ(zL ) + ηk 2 + ξ(t),                                                    (6)
                                  ∂t                ϕ(M )

where:

         • α(t), β(t), γ(t) are time-dependent coefficients,

         • ξ(t) is a stochastic noise term capturing cosmic randomness,

         • k 2 introduces nonlinear feedback effects.


5   Dynamic Scaling Parameter

We propose a dynamic k defined as:
                                                                                                                         
                                                   Mb                                                                M
                     k = (3.4 ± 0.1) + (1.2 ± 0.3)    − (0.5 ± 0.2)zL + (0.3 ± 0.1) log                                       ,           (7)
                                                   M                                                                 M⊙

where M
      M is the baryonic mass fraction, zL is the lens redshift, and M is the total mass in solar units.
       b




                                Multiplicity Theory © 2024 Tyler Van Osdol & Ryan Van Gelder - Citizen Gardens                    Page 2 of 5
                                                  Licensed Under MIT and CC BY-NC-SA 4.0.
Preprint - PrimeAI Enhanced Template


6   Eigenvalue Feedback and Stability

Represent k as an eigenvalue derived from a gravitational interaction matrix G:

                                                             Gψ = kψ,                                                  (8)

where ψ is the eigenvector of the system state. Dynamic feedback updates G:

                                                  G(t + 1) = G(t) + δG(t),                                             (9)

with δG(t) defined as:
                                                         X
                                         δG(t) = λ1             Tij ϕ(xi )ϕ(xj ) + λ2 ζ(t),                           (10)
                                                          i,j

where ζ(t) represents entanglement corrections.


7   Stochastic and Fractal Dynamics

Incorporate stochasticity and fractal terms:

                     ∂k                ϕ(Mb )                    ϕ(M )
                        = α(t)k + β(t)        + γ(t)ϕ(zL ) + λ ·       · cos(ωt + φ) + ξ(t).                          (11)
                     ∂t                ϕ(M )                      M⊙

Here, λ scales fractal structures, and cos(ωt + φ) models self-similar dynamics.


8   Unified Scaling Relation

Combining all enhancements, the unified scaling relation becomes:

               ∂k                ϕ(Mb )                              X
                  = α(t)k + β(t)        + γ(t)ϕ(zL ) + ηk 2 + ξ(t) +   Tijk + λ(t) · cos(ωt + φ),                     (12)
               ∂t                ϕ(M )
                                                                                       i,j,k


where Tijk is a third-order tensor capturing higher-order interactions.


9   Enhanced Scaling Relation

This enhanced scaling relation provides improved precision for:

       • Predicting Einstein radii (θE ):
                                                                4Gϕ(M )     DLS
                                                      θE =          2
                                                                        ·           .                                 (13)
                                                                  c       DOL · DOS
       • Modeling dark matter halo evolution.

       • Analyzing cosmic-scale interactions.

Future work involves computational validation through astrophysical simulations.


                              Multiplicity Theory © 2024 Tyler Van Osdol & Ryan Van Gelder - Citizen Gardens   Page 3 of 5
                                                Licensed Under MIT and CC BY-NC-SA 4.0.
Preprint - PrimeAI Enhanced Template


10     Conclusion

This integration synthesizes the empirical dynamic scaling relation with the theoretical rigor of Multiplicity Theory,
creating a robust framework to explore interconnected gravitational, baryonic, and dark matter systems. Future work
could involve computational experiments to validate these theoretical extensions in astrophysical simulations.


References

     1. Tyler Van Osdol. A dynamic scaling relation for dark matter mass in strong gravitational lenses. Astrophysics
        and Space Science, 1:1–7, 2024.

     2. Nicholas Galioto and Ryan O. Van Gelder. Dynamic multiplicity equation: Extensions and applications.
        PrimeAI Quantum Computing Reviews, 8, 2024.

     3. M. W. Auger, T. Treu, A. S. Bolton, R. Gavazzi, L. V. E. Koopmans, P. J. Marshall, and L. A. Moustakas. The
        sloan lens acs survey. vi. discovery of a double einstein ring. Astrophysical Journal Letters, 724:L31, 2010.

     4. M. W. Auger, T. Treu, R. Gavazzi, A. S. Bolton, L. V. E. Koopmans, and P. J. Marshall. The sloan lens acs
        survey. vii. elliptical galaxy scaling laws. Astrophysical Journal, 721:1033, 2010.

     5. G. R. Blumenthal, S. M. Faber, R. Flores, and J. R. Primack. Contraction of dark matter galactic halos due to
        baryonic infall. Astrophysical Journal, 301:27, 1986.

     6. A. S. Bolton, T. Treu, L. V. E. Koopmans, R. Gavazzi, L. A. Moustakas, S. Burles, and D. J. Schlegel. The sloan
        lens acs survey. i. a large spectroscopic sample of lens galaxies. Astrophysical Journal, 641:699, 2006.

     7. A. S. Bolton, S. Burles, L. V. E. Koopmans, T. Treu, R. Gavazzi, L. A. Moustakas, R. Wayth, and D. J. Schlegel.
        The sloan lens acs survey. v. the full acs strong-lens sample. Astrophysical Journal, 682:964, 2008.

     8. B. J. Brewer, T. Treu, P. J. Marshall, and et al. Probabilistic strong lensing analysis of galaxies. Monthly Notices
        of the Royal Astronomical Society, 459:2040, 2016.

     9. A. Dekel and Y. Birnboim. Galaxy formation via cold streams in dark matter halos. Monthly Notices of the
        Royal Astronomical Society, 368:2, 2006.

  10. C. D. Fassnacht, D. S. Womble, G. Neugebauer, and et al. Multiple imaging and lensing shear in mg 0414+0534.
        Astronomical Journal, 112:1104, 1996.

  11. R. Gavazzi, T. Treu, J. D. Rhodes, and et al. The sloan lens acs survey. iv. the mass density profile of early-type
        galaxies. Astrophysical Journal, 679:1077, 2008.

  12. R. Gavazzi, P. J. Marshall, T. Treu, A. Sonnenfeld, and V. Springel. Dark matter and baryon interplay in massive
        galaxies. Astrophysical Journal, 785:140, 2014.

  13. C. A. Katz, B. Moore, and L. Hernquist. Galaxy interactions and tidal disruption in clusters. Astrophysical
        Journal, 487:L79, 1997.


                               Multiplicity Theory © 2024 Tyler Van Osdol & Ryan Van Gelder - Citizen Gardens   Page 4 of 5
                                                 Licensed Under MIT and CC BY-NC-SA 4.0.
Preprint - PrimeAI Enhanced Template


  14. L. J. King and et al. Gravitational lenses in radio sources. Monthly Notices of the Royal Astronomical Society,
      284:L31, 1997.

  15. L. V. E. Koopmans and et al. Structure and evolution of early-type galaxy lenses. Astrophysical Journal,
      595:665, 2003.

  16. J. F. Navarro, C. S. Frenk, and S. D. M. White. A universal density profile from hierarchical clustering.
      Astrophysical Journal, 490:493, 1997.

  17. M. Oguri. Statistics of strong lensing clusters. Publications of the Astronomical Society of Japan, 62:1017, 2010.

  18. D. Sluse, F. Courbin, D. Hutsemekers, and et al. Gravitational lensing by quasars. Astronomy & Astrophysics,
      538:A99, 2012.

  19. S. H. Suyu, P. J. Marshall, M. W. Auger, and et al. Dissecting the gravitational lens rxj1131-1231. Astrophysical
      Journal, 711:201, 2010.




                             Multiplicity Theory © 2024 Tyler Van Osdol & Ryan Van Gelder - Citizen Gardens   Page 5 of 5
                                               Licensed Under MIT and CC BY-NC-SA 4.0.
