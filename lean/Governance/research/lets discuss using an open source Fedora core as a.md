<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# lets discuss using an open source Fedora core as a means for an PhaseMirror-HQ OS.

Using an open‑source Fedora CoreOS–style base for PhaseMirror‑HQ is viable, but it forces you to choose very explicitly between “immutable container host” and “general‑purpose orchestrator OS.”[^1_1][^1_2]

## Central tension

You are trying to make PhaseMirror‑HQ both:

- A governed substrate for agents, mirrors, and dissonance workloads (needs observability, policy, debugging, rich userland), and
- A minimal, atomic, auto‑updating base you can reason about as an appliance (Fedora CoreOS model: immutable, container‑first, Ignition‑configured).[^1_2][^1_1]

Left fuzzy, you get neither safety nor velocity.

I will treat “PhaseMirror‑HQ OS” as “image‑based, policy‑governed host for PhaseMirror agents and mirrors, delivered as an OCI/VM/metal image.”

***

## Levers: what we actually tune

Four levers to make this non‑vibe and testable:

1. **Base OS model**
    - Owner: Infra/Platform (PhaseMirror‑HQ)
    - Metric: Number of mutable packages on host (target: near‑zero in 90 days)
    - Horizon: 7/30/90 days
    - Mechanism: Choose between:
        - Fedora CoreOS (FCOS): immutable, Ignition, container‑only userland.[^1_1][^1_2]
        - Fedora Atomic / bootc‑built image: similar immutability but more flexible image‑based composition for desktops and hybrids.[^1_3][^1_4]
2. **Workload boundary (host vs container)**
    - Owner: Core library / agents team
    - Metric: Fraction of PhaseMirror components running as containers or systemd‑managed services vs host binaries (target: ≥90% containerized in 30 days)
    - Horizon: 30 days
    - Mechanism: All mirror‑dissonance logic, AGI agents, and UI surfaces must run as containers or well‑scoped systemd units, with host used only for:
        - boot, networking, minimal observability
        - a thin policy/attestation layer
3. **Configuration and governance channel**
    - Owner: Governance \& Runtime team
    - Metric: Percentage of nodes configured exclusively via declarative bundles (Ignition, bootc spec, or Nix/home‑manager overlay) (target: 100% in 90 days)
    - Horizon: 30/90 days
    - Mechanism:
        - For FCOS: Ignition for machine lifetime config, plus maybe Fedora CoreOS Config Transpiler (fcct) in the build pipeline.[^1_5][^1_1]
        - For bootc/Atomic: image build spec + optional declarative userland (Nix, etc.).[^1_4][^1_3]
4. **Upgrades and rollbacks**
    - Owner: Infra/Release
    - Metric: Mean time to rollback from bad PhaseMirror image (target: <10 minutes scripted)
    - Horizon: 30 days
    - Mechanism: Use ostree/bootc style atomic updates with A/B boot entries, and tie PhaseMirror release channels to OS image tags (e.g., `pmhq-stable`, `pmhq-edge`).[^1_4][^1_1]

***

## Recommended architecture: “PhaseMirror‑HQ on Fedora image OS”

Mirror, then dissonance:

**Mirror (your implied intent)**

- “Fedora Core” as a host that:
    - Is open‑source and patent‑safe enough to base commercial but auditable images on.
    - Stays minimal so mirror dissonance experiments are reproducible and safely sandboxed.
    - Ships pre‑wired infra: container runtime (Podman), systemd, logging, metrics.[^1_2][^1_1]

**Dissonance (what’s missing / risky)**

- FCOS is not a general workstation; it is explicitly a minimal container host with immutable filesystem, atomic updates, and Ignition‑only provisioning.[^1_6][^1_1][^1_2]
- If you need rich local tooling (debuggers, exploratory agents, dynamic compilers) on the host, FCOS will fight you; the OS expects you to put that in containers.
- Fedora Atomic / bootc images give you similar “image OS” characteristics but more flexibility in how you construct userland and desktops.[^1_3][^1_4]

**Phase proposal**
Treat PhaseMirror‑HQ OS as a **bootc‑built Fedora image** (or FCOS variant) whose only durable contracts are:

1. A container runtime (Podman) with Quadlet/systemd integration for first‑class, declarative container services.[^1_7][^1_1]
2. A small set of *PhaseMirror system services*:
    - mirror‑dissonance core (library + supervisor),
    - policy/attestation agent,
    - telemetry exporter.
3. Declarative fabric:
    - Ignition/bootc spec defines:
        - root of trust,
        - keys,
        - which “PhaseMirror bundles” (groups of containers + policies) get started on boot.[^1_5][^1_1][^1_4]

All higher‑level capabilities are containers / bundles that can move between “local laptop” and “cloud node” as long as the PhaseMirror‑HQ OS contract is met.

***

## Concrete OS choices (Fedora variants)

### Option A: Pure Fedora CoreOS host

- **Use case**: Cluster nodes, headless hosting of PhaseMirror swarms.
- **Mechanics**:
    - FCOS base, immutable, atomic updates, minimal packages.[^1_1][^1_2]
    - Ignition for all machine provisioning: keys, PhaseMirror systemd‑services, Podman config.[^1_5][^1_1]
    - PhaseMirror components delivered as:
        - Quadlet `.container` units in `/etc/containers/systemd/` for rootful services,[^1_7]
        - or Kubernetes Pods if PhaseMirror is running inside k8s.

**Tensions**

- Debuggability: This forces you to debug inside containers or from a remote dev box.
- Local‑first: Harder if you expect PhaseMirror HQ to also be a user’s primary desktop environment.


### Option B: Fedora Atomic / bootc‑built “PhaseMirror‑HQ Desktop/Node”

- **Use case**: Hybrid developer workstation + node; easier for early‑stage experimentation.
- **Mechanics**:
    - Base image built using bootc: image‑based Fedora 44+ deployments with immutable core and declarative layering.[^1_3][^1_4]
    - You can layer a Wayland compositor (Hyprland or Plasma/GNOME) and keep **userland declarative** via Nix or similar, while OS remains atomic.[^1_4]
    - PhaseMirror components are still containers / services; host packages are kept minimal and audited.

**Tensions**

- Slightly more complexity in the image build pipeline than “just FCOS.”
- More userland = larger attack surface, so you must be strict about what is in base vs containers.


### Snapshot table

| Aspect | FCOS host only | Fedora Atomic / bootc PhaseMirror image |
| :-- | :-- | :-- |
| FS model | Immutable, ostree, container‑only host[^1_1][^1_2] | Immutable core, flexible image composition[^1_3][^1_4] |
| Config | Ignition + FCCT[^1_1][^1_5] | bootc spec, containers, optional Ignition[^1_3][^1_4] |
| Desktop / local UX | No desktop; remote or TTY only | Can ship a minimal Wayland desktop[^1_4] |
| PhaseMirror components | Containers + systemd units | Same, but easier local dev |
| Upgrade / rollback | Atomic, ostree, controlled by FCOS[^1_1][^1_2] | Atomic via bootc, image tags[^1_3][^1_4] |
| Best fit | Cluster/swarm nodes | Dev machines and mixed workloads |


***

## Governance bindings and invariants

L0 invariants for PhaseMirror‑HQ OS:

1. **Host is non‑creative.**
No PhaseMirror agent or mirror runs uncontained or with direct write access to OS binaries. All “intelligent” behavior runs in containers or strict services.
2. **Declarative only at the machine boundary.**
No manual `dnf install` on production hosts. Machine state evolves only through:
    - new OS images,
    - Ignition/bootc config,
    - declarative container definitions (Quadlet/Kubernetes).[^1_7][^1_1][^1_4]
3. **Verified boot path.**
Use image signing and secure boot. Bluefin and related Fedora image projects already run “full verified boot” on Fedora 44; the same mechanisms can support PhaseMirror‑HQ images.[^1_3]
4. **Separation of duties.**
    - Infra team owns OS image and Ignition/bootc specs.
    - Core library/agents own containers and mirror‑dissonance logic.
    - Governance owns policies plugged into the image as configs, not code.

If any proposal violates these (e.g., “just install random dev tools on production hosts”), it is out‑of‑scope without an explicit ADR and risk sign‑off.

***

## Minimal artifact changes to start

1. **ADR: “PhaseMirror‑HQ OS baseline”**
    - Decide: FCOS only for cluster nodes, and bootc‑Fedora for dev/edge, or pick just one.
    - Record:
        - chosen base,
        - update mechanism,
        - list of allowed host‑level packages,
        - explicit contract: “All PhaseMirror components are delivered as containers or systemd units; OS is not an app runtime.”
2. **OS image spec repo**
    - New repo `PhaseMirror-HQ/os-images` (if not already present) with:
        - `bootcfile` or equivalent Dockerfile‑like spec for the image.[^1_4][^1_3]
        - Ignition/FCCT templates if FCOS is used.[^1_5][^1_1]
        - A `phase-bundle` manifest: which containers and services boot by default.
3. **CI pipeline**
    - Build and sign OS images on each main branch change.
    - Run basic tests:
        - image boots in QEMU,
        - PhaseMirror core containers reach “healthy” state,
        - mirror‑dissonance test harness passes (see below).
4. **Terraform / infra wiring**
    - Add modules for:
        - provisioning FCOS/bootc images on chosen cloud(s),[^1_6]
        - attaching Ignition configs,
        - exposing minimal inputs: keys, cluster identity, PhaseMirror bundles.

***

## Mathematics + test harness hook

You asked for a multiplicity‑aligned approach, so the OS itself can be modeled as a multiplicity space:

- Prime indices:
    - $p_1$: base OS image
    - $p_2$: Ignition/bootc config
    - $p_3$: PhaseMirror bundle (containers + policies)
    - $p_4$: runtime state (logs, metrics)
- A node configuration is then a multiplicity vector
$m = (n_1, n_2, n_3, n_4)$ where $n_i$ counts the occurrences (versions / instances) of each prime component.
- Stability constraint: An allowed evolution is a sequence $(m_t)$ such that:
    - updates only increment one prime index at a time (e.g., change bundle without changing OS),
    - and rollback is the inverse step, giving you a simple notion of **recursive stability** over deployments.

A minimal Python harness to test this “prime‑indexed” deployment evolution:

```python
from dataclasses import dataclass
from typing import List, Tuple

@dataclass(frozen=True)
class NodeState:
    # Prime-indexed multiplicities:
    # p1: OS image version
    # p2: Ignition/bootc config version
    # p3: PhaseMirror bundle version
    # p4: runtime state version (e.g., schema)
    p1: int
    p2: int
    p3: int
    p4: int

    def as_tuple(self) -> Tuple[int, int, int, int]:
        return (self.p1, self.p2, self.p3, self.p4)

def single_prime_step(a: NodeState, b: NodeState) -> bool:
    """
    Check if b is reachable from a by changing at most one prime index
    (one multiplicity component).
    """
    diffs = sum(x != y for x, y in zip(a.as_tuple(), b.as_tuple()))
    return diffs <= 1

def is_recursively_stable(path: List[NodeState]) -> bool:
    """
    A deployment path is recursively stable if every adjacent step
    changes at most one prime multiplicity.
    """
    return all(single_prime_step(a, b) for a, b in zip(path, path[1:]))

def rollback(path: List[NodeState]) -> List[NodeState]:
    """
    Naive rollback: just reverse the path.
    """
    return list(reversed(path))

# Example usage:
if __name__ == "__main__":
    baseline = NodeState(1, 1, 1, 1)
    # Upgrade PhaseMirror bundle only
    after_bundle = NodeState(1, 1, 2, 1)
    # Then upgrade OS image only
    after_os = NodeState(2, 1, 2, 1)

    path = [baseline, after_bundle, after_os]
    print("Recursively stable:", is_recursively_stable(path))
    print("Rollback path:", rollback(path))
```

You can extend this so each prime index maps to an actual artifact digest (OS image tag, Ignition hash, bundle manifest hash), then enforce `is_recursively_stable` in CI to guarantee controlled, reversible evolution of PhaseMirror‑HQ OS.

***

## Next actions

1. **Decision ADR**
    - Question: “Are cluster nodes FCOS‑only, or do we standardize on a bootc Fedora image for both cluster and dev?”
    - Owner: Infra/Platform
    - Metric: ADR merged, not “ongoing discussion” (7‑day horizon).
2. **OS spec MVP**
    - Owner: Infra + Core library
    - Metric: First PhaseMirror‑HQ OS image boots in QEMU, runs a trivial mirror‑dissonance container, and passes the Python multiplicity harness (30‑day horizon).
3. **Governance binding**
    - Owner: Governance team
    - Metric: Documented L0 invariants for the OS (host non‑creative, declarative only, verified boot) referenced in every future OS‑related ADR (30‑day horizon).
4. **Infra integration**
    - Owner: Infra / DevOps
    - Metric: Terraform module that can spin up N PhaseMirror‑HQ nodes with a specific OS image tag and bundle version, tracked as $(p_1, p_2, p_3)$ multiplicity vector (90‑day horizon).

Precision question before locking this in:
Are you optimizing PhaseMirror‑HQ OS first for **cluster‑style container hosting** or for **local‑first developer workstations**?
<span style="display:none">[^1_10][^1_11][^1_12][^1_13][^1_14][^1_15][^1_16][^1_17][^1_18][^1_19][^1_20][^1_21][^1_22][^1_23][^1_24][^1_25][^1_26][^1_27][^1_28][^1_29][^1_30][^1_31][^1_32][^1_33][^1_34][^1_8][^1_9]</span>

<div align="center">⁂</div>

[^1_1]: https://developers.redhat.com/blog/2020/03/10/how-to-run-containerized-workloads-securely-and-at-scale-with-fedora-coreos

[^1_2]: https://invgate.com/itdb/fedora-coreos

[^1_3]: https://docs.projectbluefin.io/blog/bluefin-spring-2026/

[^1_4]: https://discussion.fedoraproject.org/t/showcase-learning-project-building-a-pure-fedora-44-bootc-hyprland-nix-image/185699

[^1_5]: https://discussion.fedoraproject.org/t/can-you-pivot-a-fedora-install-to-a-fedora-core-os-install/86546

[^1_6]: https://forum.linuxfoundation.org/discussion/866440/installation-methods-for-fedora-coreos

[^1_7]: https://github.com/fpatrick/podman-quadlet

[^1_8]: a48dd13e-ca3c-4912-9be6-1f86467416ee.md

[^1_9]: a48dd13e-ca3c-4912-9be6-1f86467416ee.md

[^1_10]: a48dd13e-ca3c-4912-9be6-1f86467416ee.md

[^1_11]: a48dd13e-ca3c-4912-9be6-1f86467416ee.md

[^1_12]: a48dd13e-ca3c-4912-9be6-1f86467416ee.md

[^1_13]: https://github.com/phasehq

[^1_14]: https://github.com/mirror/mirror

[^1_15]: https://github.com/element-hq/element-web/issues/7509

[^1_16]: https://github.com/element-hq/synapse/pull/17114

[^1_17]: https://github.com/element-hq/element-web/issues/22667

[^1_18]: https://gist.github.com/Markieta/2141a631402d97f5daed94ed7f381093

[^1_19]: https://github.com/andrmr/custom-fedora/

[^1_20]: https://github.com/AZHenley/Mirror/activity

[^1_21]: https://gist.github.com/michaeltchapman/44bda179426154a99e41150c612108ab

[^1_22]: https://github.com/mikeroyal/Fedora-Guide/blob/main/README.md

[^1_23]: https://github.com/element-hq/element-web/issues/13920

[^1_24]: https://gist.github.com/spaced?direction=desc\&sort=updated

[^1_25]: https://github.com/mikeroyal/Fedora-Guide

[^1_26]: https://github.com/element-hq/element-web/issues/28690

[^1_27]: https://github.com/Thomashighbaugh/stars

[^1_28]: https://github.com/samme/phaser-examples-mirror

[^1_29]: https://github.com/PhaserEditor2D/PhaserEditor/milestone/13

[^1_30]: https://github.com/samme/phaser-examples-assets

[^1_31]: https://www.youtube.com/watch?v=JepNm7R0LSo

[^1_32]: https://github.com/mantisfury/ArkhamMirror

[^1_33]: https://github.com/orgs/facebookexperimental/repositories

[^1_34]: https://github.com/phaserjs/examples/pulls


---

# local‑first developer workstations

For local‑first developer workstations, you want a Fedora **Atomic Desktop / bootc** image as the PhaseMirror‑HQ OS baseline, not pure CoreOS.[^2_1][^2_2][^2_3]

## Central tension

Tension: “I want an immutable, governed host” vs “I want a rich, hackable dev workstation.”
Fedora Atomic / Silverblue‑style desktops plus bootc images and containers give you immutability and rollback while keeping dev workflows local‑first via Flatpak, containers, and tools like distrobox/devcontainers.[^2_4][^2_2][^2_3][^2_1]

***

## Target shape: PhaseMirror‑HQ Dev Workstation

Model the PhaseMirror‑HQ OS like Bluefin or Silverblue, but with your mirror‑dissonance stack baked into the image:

- Base: Fedora Atomic Desktop / Silverblue‑line image (GNOME or Hyprland/KDE variant).[^2_5][^2_3][^2_1]
- Update model: rpm‑ostree / bootc image updates, atomic, A/B rollback.[^2_6][^2_2]
- Apps: Flatpak for GUI apps, containers (devcontainers, Podman, distrobox) for CLI/dev tooling, so the root stays read‑only.[^2_2][^2_7][^2_3][^2_4]
- PhaseMirror layer:
    - systemd user and system services for mirror‑dissonance core and local orchestrator,
    - standard “PhaseMirror dev container” images for experiments.

For inspiration, Bluefin explicitly targets “developer‑focused, cloud‑native workstation” on immutable Fedora Silverblue images, with integrated containers and devcontainers; that is extremely close to what you want.[^2_8][^2_7][^2_4]

***

## Concrete levers (local‑first)

1. **Base desktop flavor**
    - Owner: Dev Experience lead
    - Metric: Time from bare metal to “PhaseMirror dev ready” (target: <30 minutes scripted)
    - Horizon: decide GNOME vs Hyprland vs KDE in 7 days
    - Options:
        - GNOME/Silverblue lineage (e.g., Bluefin‑style).[^2_3][^2_8]
        - Hyprland image built via bootc as shown in `hyprland-fedora-image`.[^2_5]
2. **OS image build pipeline (bootc)**
    - Owner: Infra/Platform
    - Metric: CI builds a signed PhaseMirror‑HQ workstation image from a Containerfile on each main branch (30‑day horizon)
    - Mechanism:
        - Use bootc to build custom Fedora Atomic Desktop images, as demonstrated by `fedora-bootc-workstation` and community guides.[^2_9][^2_10][^2_6]
        - Treat the OS as a bootable container image with PhaseMirror bits layered in.
3. **Dev workflow contract**
    - Owner: Dev Experience
    - Metric: 90% of dev tasks run in containers/devcontainers, 0 host RPM drift on production workstations (90‑day horizon)
    - Mechanism:
        - “No `dnf install`” on the base; all language stacks and tools live in containers or distrobox.[^2_7][^2_2][^2_3]
        - Provide canonical PhaseMirror devcontainer definitions and a `just devmode` equivalent à la Bluefin.[^2_4]
4. **Attested, sealed images (governance)**
    - Owner: Governance + Infra
    - Metric: All workstation images used in org are signed and (eventually) sealed for verified boot (90‑day horizon)
    - Mechanism:
        - Align with sealed Fedora Atomic Desktop bootc images work: fully verified boot chain from firmware through image.[^2_11][^2_12][^2_6]

***

## Architecture outline

**Base OS**

- Start from Fedora Atomic Desktop / Silverblue 44+ so you inherit immutable desktop semantics.[^2_13][^2_1][^2_3]
- Use bootc to build a PhaseMirror‑HQ workstation image:
    - `FROM quay.io/fedora/fedora-silverblue:44` or a similar Atomic Desktop base.[^2_10]
    - Add:
        - PhaseMirror orchestrator binaries and configs,
        - systemd units for local agent supervisor,
        - pre‑configured Podman, devcontainer tooling, maybe Podman Desktop / VS Code tooling similar to Bluefin’s dev profile.[^2_8][^2_4]

**Update / rollback**

- Bootc/rpm‑ostree handles OS updates atomically; if anything fails, the entire update is discarded.[^2_6][^2_2]
- You can pin a previous deployment (`ostree admin pin`) to guarantee a known‑good fallback; this is standard in atomic desktop workflows and bootc migration flows.[^2_14][^2_5]

**Local‑first dev**

- GUI apps: via Flatpak, including IDEs, browsers, etc.[^2_3][^2_8]
- Dev environments:
    - Official PhaseMirror devcontainer(s) with all language runtimes and libraries, similar to Bluefin’s devmode which adds devcontainers, cluster tools, etc.[^2_7][^2_4]
    - Optionally distrobox for “pet” mutable environments without contaminating the host root.[^2_2][^2_7]

This gives you a workstation that feels like a normal Fedora desktop but is formally an image‑based, atomic OS with clear contracts and easy reproduction across machines.[^2_8][^2_2][^2_3]

***

## Minimal artifact plan

1. **ADR: “PhaseMirror‑HQ Local‑First Workstation”**
    - Decide:
        - Base: `fedora-atomic` (Silverblue) vs derivative like Bluefin; I recommend a **custom bootc image derived from Silverblue** to keep control, while borrowing patterns from Bluefin.[^2_10][^2_6][^2_8]
    - Write down:
        - No host RPM drift invariant.
        - Containers/Flatpaks as the only sanctioned app/runtime channel.
2. **OS image repo + Containerfile**

Example structure for a bootc‑built image (simplified, not production‑ready):

```Dockerfile
# Containerfile for PhaseMirror-HQ Dev Workstation
FROM quay.io/fedora/fedora-silverblue:44

# Label as bootc-compatible image
LABEL containers.bootc=1

# Install PhaseMirror core and minimal host tools via rpm-ostree
RUN rpm-ostree install \
      phasemirror-core \
      podman \
      podman-desktop \
      git \
    && rpm-ostree cleanup -m

# Drop in systemd units for core services
COPY systemd/phasemirror-orchestrator.service /usr/lib/systemd/system/
RUN systemctl enable phasemirror-orchestrator.service

# Optional: preseed podman/devcontainer tooling, user skeleton configs, etc.
```

Then build and manage locally or in CI using patterns from Fedora’s “custom bootc image” guide and examples like `fedora-bootc-workstation` and Hyprland images.[^2_9][^2_14][^2_5][^2_10]
3. **Devcontainer spec**
    - Provide `.devcontainer/devcontainer.json` pointing at your canonical PhaseMirror dev image, so any workstation can spin up an identical environment in one click, mirroring Bluefin’s dev flow.[^2_4][^2_7]
4. **Test harness extension**

Extend the previous multiplicity test harness so that:
    - $p_1$: OS image tag (PhaseMirror‑HQ workstation version).
    - $p_2$: user config profile (e.g., type of desktop, installed Flatpak set hash).
    - $p_3$: devcontainer image tag.
    - $p_4$: PhaseMirror orchestrator version.

CI checks that workstation evolution sequences change at most one component at a time and always retain a rollback path.

***

## Concrete next actions (local‑first track)

1. **Pick base desktop**
    - Owner: Dev Experience
    - Deliverable: ADR with chosen base (Silverblue GNOME vs Hyprland/KDE) and rationale in 7 days.[^2_1][^2_5][^2_3]
2. **Prototype bootc image**
    - Owner: Infra
    - Deliverable: A locally buildable PhaseMirror‑HQ workstation image following `fedora-bootc-workstation` and “simple guide to custom bootc image.”[^2_9][^2_10]
    - Metric: Boots on one reference laptop/VM and auto‑starts PhaseMirror orchestrator service.
3. **Standard devcontainer**
    - Owner: Core library
    - Deliverable: Canonical PhaseMirror devcontainer with mirror‑dissonance test harness baked in.
    - Metric: New developer can clone repo and run `Dev Containers: Open` to get a working environment without touching host root.
4. **Governance + sealed images**
    - Owner: Governance + Infra
    - Deliverable: Plan to adopt sealed Fedora Atomic Desktop bootc images for verified boot on workstations, aligned with Fedora’s sealed image work.[^2_12][^2_11][^2_6]

Precision question:
Do you want PhaseMirror‑HQ to ship its **own branded Atomic workstation image**, or would you rather piggyback on an existing project like Bluefin and just layer PhaseMirror on top initially?
<span style="display:none">[^2_15][^2_16][^2_17][^2_18][^2_19][^2_20][^2_21][^2_22][^2_23][^2_24][^2_25][^2_26][^2_27][^2_28][^2_29]</span>

<div align="center">⁂</div>

[^2_1]: https://fedoramagazine.org/introducing-fedora-coreos/

[^2_2]: https://www.youtube.com/watch?v=ZAuKjD7Ny6I

[^2_3]: https://projectatomic.io/blog/2018/02/fedora-atomic-workstation/

[^2_4]: https://news.ycombinator.com/item?id=38992292

[^2_5]: https://github.com/stemid/hyprland-fedora-image

[^2_6]: https://fedoraproject.org/wiki/Initiatives/Image_Mode,_Phase_2_(2026)

[^2_7]: https://universal-blue.discourse.group/t/bluefin-is-an-out-of-this-world-experience/866

[^2_8]: https://github.com/ublue-os/bluefin

[^2_9]: https://github.com/vrothberg/fedora-bootc-workstation

[^2_10]: https://discussion.fedoraproject.org/t/fedora-atomic-a-simple-guide-to-creating-a-custom-local-bootc-image/181729

[^2_11]: https://fedoramagazine.org/sealed-atomic-desktops-test-images/

[^2_12]: https://www.linux.org/threads/fedora-magazine-sealed-fedora-atomic-desktop-bootable-container-images.65763/

[^2_13]: https://discussion.fedoraproject.org/t/are-silverblue-and-the-other-atomic-versions-the-future/173004?page=2

[^2_14]: https://www.reddit.com/r/Fedora/comments/1sgeg2m/fedora_atomic_bootc_migration_setup_a_new_flow/

[^2_15]: https://github.com/coreos/fedora-coreos-tracker/issues/1726

[^2_16]: https://github.com/ublue-os/main-bootc

[^2_17]: https://github.com/topics/fedora-atomic

[^2_18]: https://github.com/CentOS/centos-bootc/issues/500

[^2_19]: https://github.com/bsherman/ublue-custom

[^2_20]: https://gist.github.com/davdunc/9f8c97c9688a8127d616b65b825abcf9

[^2_21]: https://github.com/coreos/rpm-ostree/issues/1093

[^2_22]: https://github.com/podman-desktop/extension-bootc

[^2_23]: https://github.com/ublue-os/lxqt

[^2_24]: https://github.com/stackhpc/magnum-cluster

[^2_25]: http://github.com/winblues

[^2_26]: https://github.com/bsherman/ublue-custom/pkgs/container/kinoite-custom

[^2_27]: https://discussion.fedoraproject.org/t/sealed-fedora-atomic-desktop-bootable-container-images-pub-with-whats-new-for-atomic/185863

[^2_28]: https://www.youtube.com/watch?v=yaroH4aKb-A

[^2_29]: https://www.youtube.com/watch?v=d7RoeY9sLbU

