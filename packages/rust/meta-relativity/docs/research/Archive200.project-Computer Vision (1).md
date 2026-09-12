---
slug: archive200-project-computer-vision-1
status: draft
created: '2026-03-20'
updated: '2026-03-20'
version: 0.1.0
tags:
- multiplicity
traceability:
  path: 04-domains/meta-relativity/Archive200.project-Computer Vision (1).md
  last_synced: '2026-03-20T17:17:18.945093Z'
---

Archive200 _Computer Vision


The Principle of Computational Equivalence suggests that most complex systems are
computationally sophisticated, requiring significant computational work to predict their
behavior. This poses a challenge for modeling the universe, as we can't simulate it for the entire
duration.

However, there are pockets of computational reducibility within these complex systems.
Surprisingly, some of these pockets align with known physics, allowing us to gain meaningful
insights despite the overall complexity.

In essence, while the universe's complexity is daunting, there are unexpected simplifications
that make our models useful for understanding it.




                    The Dimensionality of Space
Simple rules can create recognizable two-dimensional surfaces, but these grids don't capture
the complexity of our three-dimensional universe. To model our universe better, we need rules
that account for three dimensions, allowing for more intricate interactions and realistic
representations.

                 Curvature in Space & Einstein’s Equations
Here are a few structures that simple examples of our rules make:




&#10005
GraphicsRow[{ResourceFunction[​
    "WolframModel"][{{1, 2, 2}, {1, 3, 4}} -> {{4, 5, 5}, {5, 3, ​
             2}, {1, 2, 5}}, {{0, 0, 0}, {0, 0, 0}}, 1000,
"FinalStatePlot"],​
   ResourceFunction[​
    "WolframModel"][{{1, 1, 2}, {1, 3, 4}} -> {{4, 4, 5}, {5, 4, ​
             2}, {3, 2, 5}}, {{0, 0, 0}, {0, 0, 0}}, 1000,
"FinalStatePlot"],​
   ResourceFunction[​
    "WolframModel"][{{1, 1, 2}, {3, 4, 1}} -> {{3, 3, 5}, {2, 5, ​
      1}, {2, 6, 5}}, {{0, 0, 0}, {0, 0, 0}}, 2000, ​
   "FinalStatePlot"]}, ImageSize -> Full]

Different surfaces can be characterized them is by their local curvature. In according to these
models, curvature is a concept closely related to dimension—and this fact will actually be
critical in understanding, for example, how gravity arises.

The following explained measure curvature on a hypergraph. Normally the area of a circle is
πr2. But let’s imagine that we’ve drawn a circle on the surface of a sphere, and now we’re
measuring the area on the sphere that’s inside the circle:




&#10005




Computing a Model.:
cappedSphere[angle_] := ​
  Module[{u, v}, ​
       With[{spherePoint = {Cos[u]
Sin[v], Sin[u] Sin[v], Cos[v]}}, ​
    Graphics3D[{First@​

ParametricPlot3D[spherePoint,    {v,
#1, #2}, {u, 0, 2 \[Pi]}, ​
            Mesh -> None, ##3] & @@@
{{angle, \[Pi], ​
                       PlotStyle ->
Lighter[Yellow, .5]}, {0, angle, ​
           PlotStyle -> Lighter[Red,
.3]}}, ​
      First@ParametricPlot3D[​
          spherePoint /. v -> angle,
{u, 0, 2 \[Pi]}, ​
          PlotStyle -> Darker@Red]},
Boxed -> False, ​
         SphericalRegion -> False,
Method -> {"ShrinkWrap" -> True}]]];​
Show[GraphicsRow[Riffle[cappedSphere
/@ {0.3, Pi/6, .8}, Spacer[30]]],​
  ImageSize -> 250]


The area (πr2 ), and after π                                , where a is the radius of the sphere.
In other words, as the radius of the circle gets bigger, the effect of being on the sphere is ever
more important. (On the surface of the Earth, imagine a circle drawn around the North Pole;
once it gets to the equator, it can never get any bigger.)

If we generalize to d dimensions, it turns out the formula for the growth rate of the volume is


                          , where R is a mathematical object known as the Ricci scalar
curvature.



The growth rates of spherical balls in hypergraphs show two contributions: a leading term
representing the effective dimension (rdr^d) and a correction term representing curvature
(r2r^2). This helps us understand the geometric properties of hypergraphs.



Here’s an example. Instead of giving a flat estimate of dimension (here equal to 2), we have
something that dips down, reflecting the positive (“sphere-like”) curvature of the surface:
&#10005
res = CloudGet["https://wolfr.am/L1ylk12R"];​
GraphicsRow[{ResourceFunction["WolframModelPlot"][​
   ResourceFunction[​
     "WolframModel"][{{1, 2, 3}, {4, 2, 5}} -> {{6, 3, 1}, {3, 6, ​
       4}, {1, 2, 6}}, {{0, 0, 0}, {0, 0, 0}}, 800, "FinalState"]], ​
  ListLinePlot[res, Frame -> True, ​
   PlotStyle -> {Hue[0.9849884156577183, 0.844661839156126, 0.63801], ​
     Hue[0.05, 0.9493847125498949, 0.954757], Hue[​
     0.0889039442504032, 0.7504362741954692, 0.873304], Hue[​
     0.06, 1., 0.8], Hue[0.12, 1., 0.9], Hue[0.08, 1., 1.], Hue[​
     0.98654716551403, 0.6728487861309527, 0.733028], Hue[​
     0.04, 0.68, 0.9400000000000001], Hue[​
     0.9945149844324427, 0.9892162267509705, 0.823529], Hue[​
     0.9908289627180552, 0.4, 0.9]}]}]




nd here they are for a more complicated structure:




&#10005
(*https://www.wolframcloud.com/obj/wolframphysics/TechPaper-P
rograms/\​
Section-04/Geodesics-01.wl*)​
​
CloudGet["https://wolfr.am/L1PH6Rne"];(*Geodesics*)​
​
gtest = UndirectedGraph[​
   Rule @@@ ​
    ResourceFunction[​
        "WolframModel"][{{x, y}, {x, z}} -> {{x, z}, {x, w},
{y, w}, {z,​
         w}}, {{1, 2}, {1, 3}}, 10, "FinalState"], Sequence[​
                                     VertexStyle            ->
ResourceFunction["WolframPhysicsProjectStyleData"][​
     "SpatialGraph", "VertexStyle"], ​
                                         EdgeStyle          ->
ResourceFunction["WolframPhysicsProjectStyleData"][​
     "SpatialGraph", "EdgeLineStyle"]] ];​
Geodesics[gtest, #] & /@ {{{79, 207}}, {{143, 258}}}




Geodesics - Physics contributions



 Einstein’s general relativity, observing the paths that light (or objects in “free fall”) follows in
space. The theory gravity is associated with curvature in space. So, when something is
deflected going around the Sun, that happens because space around the Sun is curved, so the
geodesic the object follows is also curved.

General relativity’s description of curvature in space turns out to all be based on the Ricci scalar
curvature R that we encountered above (as well as the slightly more sophisticated Ricci tensor).
A good practice to following, such as models reproducing Einstein’s equations for gravity is to
use the Ricci curvatures that arise from our hypergraphs are the same as the theory implies.




                                    Definition of Time



In our models, space is defined by the large-scale structure of the hypergraph. Unlike the
traditional view that equates space and time, we see time as the progressive application of
rules that update the universe's structure. This computational view of time aligns with relativity
and highlights the phenomenon of computational irreducibility, influencing concepts like
entropy and the arrow of time.

This approach suggests that as time progresses, we observe more steps in a computation, and
computational irreducibility provides a fundamental explanation for the thermodynamic arrow
of time and entropy increase. The integration of modern computational paradigms with
physical theories may have changed the course of physics history.




Here is the crucial point: this is not the only sequence of updating events consistent with the
rule. The rule just says to find two adjacent connections, and if there are several possible
choices, it says nothing about which one. And a crucial idea in our model is in a sense just to
do all of them.

We can represent this with a graph that shows all possible paths:




 &#10005
 CloudGet["https://wolfr.am/LmHho8Tr"]; (*newgraph*)newgraph[​
  Graph[ResourceFunction["MultiwaySystem"][​
     "WolframModel" -> {{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z,​
           w}}}, {{{1, 2}, {2, 3}, {3, 4}, {2, 4}}}, 3, "StatesGraph", ​
     VertexSize -> 3, PerformanceGoal -> "Quality"], ​
   AspectRatio -> 1/2], {3, 0.7}]
For the very first update, there are two possibilities. Then for each of the results of these, there
are four additional possibilities. But at the next update, something important happens: two of
the branches' merges. In other words, even though we have done a different sequence of
updates, the outcome is the same.
Things rapidly get complicated. Here is the graph after one more update, now no longer trying
to show a progression down the page:




&#10005
Graph[ResourceFunction["MultiwaySystem"][​
  "WolframModel" -> {{{x, y}, {x, z}} -> {{x, z}, {x, w}, {y, w}, {z, ​
       w}}}, {{{1, 2}, {2, 3}, {3, 4}, {2, 4}}}, 4, "StatesGraph", ​
  VertexSize -> 3, PerformanceGoal -> "Quality"]]




              The Graph of Causal Relationships
rules that operate on strings of characters. (To clarify: these are not the strings of string
theory—although in a bizarre twist of “pun-becomes-science” I suspect that the continuum
limit of the operations I discuss on character strings is actually related to string theory in the
modern physics sense.)



Definiton and Rules


A → BBB, BB → A}
This rule says that anywhere we see an A, we can replace it with BBB, and anywhere we see BB
we can replace it with A. So now we can generate what we call the multiway system for this
rule, and draw a “multiway graph” that shows everything that can happen:
The multiway graph by including the updating events that lead to each transition between
states:
Both pictures representing causal relationships between events would always be:
The same image with a different prospect in position.
             The Importance of Causal Invariance
the case of the rule BA→AB. This rule says that any time there’s a B followed by an A in a
string, swap these characters around. In other words, this is a rule that tries to sort a string into
alphabetical order, two characters at a time.

Let’s say we start with BBBAAA. Then here’s the multiway graph that shows all the things that
can happen according to the rule:




A model of fundamental physics, critical to both relativity and quantum mechanics.

Causal invariance has been seen before in various guises in mathematics, mathematical logic
and computer science. (Its most common name is “confluence”, though there are some
technical differences between this and what I call causal invariance.).
Think about expanding out an algebraic expression, like (x + (1 + x)2)(x + 2)2

(x+\!\(\*SuperscriptBox[\((1+x)\),\(2\)]\))\!\(\*SuperscriptBox[\((x+2)\),\(2\)]\)). You could expand
one of the powers first, then multiply things out. Or you could multiply the terms first. It doesn’t
matter what order you do the steps in; you’ll always get the same canonical form (which in this
case Mathematica tells me is 4 + 16x + 17x2 + 7x3 + x4

4+16x+\!\(\*SuperscriptBox[\(17x\),\(2\)]\)+\!\(\*SuperscriptBox[\(7x\),\(3\)]\)\!\(\*SuperscriptBox[\(x\),\(4\)]\)).
And this independence of orders is essentially causal invariance.

Here’s one more example. Imagine you’ve got some recursive definition, say f[n_]:=f[n-1]+f[n-2]
f[n_]:=f[n-1]+f[n-2] (with f[0]=f[1]=1

f[0]=f[1]=1). Now evaluate f[10]

f[10]. First you get f[9]+f[8]

f[9]+f[8]. But what do you do next? Do you evaluate f[9]

f[9], or f[8]

f[8]? And then what? In the end, it doesn’t matter; you’ll always get 55. And this is another example of causal
invariance.

This example explained a coding process.:

centeredRange[n_] := # - Mean@# &@Range@n;​
centeredLayer[n_] := {#, n} & /@ centeredRange@n;​
diamondLayerSizes[layers_?OddQ] := ​
  Join[#, Reverse@Most@#] &@Range[(layers + 1)/2];​
diamondCoordinates[layers_?OddQ] := ​
  Catenate@MapIndexed[​
    Thread@{centeredRange@#, (layers - First@#2)/2} &, ​
    diamondLayerSizes[layers]];​
diamondGraphLayersCount[graph_] := 2 Sqrt[VertexCount@graph] - 1;​
With[{graph = ​
   ResourceFunction["SubstitutionSystemCausalGraph"][{"BA" -> "AB"}, ​
    "BBBBAAAA", 12]}, ​
 Graph[graph, ​
  VertexCoordinates -> ​
   diamondCoordinates@diamondGraphLayersCount@graph, VertexSize -> .2]]
Casual connections, more specific Grids.




In modeling the universe, we can't place the observer outside the system because the observer
is inherently part of the universe. This means that the observer's perception is continuously
updated by a series of events. The observer can only experience the causal relationships
between events, represented by a causal graph. In a simplified model using the BA→AB rule
for strings, the observer's understanding is limited to the causal graph, rather than the spatial
layout of the string.




             Understanding Foliation and Events:
   ●​ Foliation: This involves dividing the universe into slices, or "leaves," representing
      simultaneous events from the perspective of an observer.
   ●​ Updating Events: These are the changes or interactions that occur within each slice.



                Implications for Updating Events:
   ●​ Maximal Simultaneity: Within each slice of the foliation, as many events as possible
      happen simultaneously. This means that events occurring within the same slice are
      considered to happen at the same time from the observer's viewpoint.
   ●​ Causal Relationships: The order of events is determined by the causal graph, which
      maps out how events influence each other. Even if events occur simultaneously within a
      slice, their causal connections dictate the sequence of their updates.
   ●​ Observer's Perspective: The motion and inertia of the observer affect how these slices
      are viewed. A moving observer might perceive different slices compared to a stationary
      one, altering the apparent simultaneity of events.
