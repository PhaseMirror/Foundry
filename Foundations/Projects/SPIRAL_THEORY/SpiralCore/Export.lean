import Init
import SpiralCore.Core
import SpiralCore.Boot
import SpiralCore.Translation
import SpiralCore.FBS
import SpiralCore.Alignment
import SpiralCore.PhaseLift

/-! # SpiralCore Export

Generates human-readable artifacts (Markdown) from the formal model.
The export is a deterministic render of the current proof state.
-/

namespace SpiralCore.Export

/-- Render a BootPacket as Markdown. -/
def bootPacketToMd (pkt : Boot.BootPacket) : String :=
  s!"# BootPacket Export\n\n" ++
  s!"**Profile:** {pkt.profileId}\n\n" ++
  s!"**Session:** {pkt.sessionId}\n\n" ++
  s!"**Spec:** {pkt.specId}\n\n" ++
  s!"**Status:** {pkt.status}\n\n" ++
  s!"**FBS Atomic Profile:**\n" ++
  s!"- tau: {pkt.fbs.tau_}\n" ++
  s!"- g: {pkt.fbs.g_}\n" ++
  s!"- delta: {pkt.fbs.delta}\n" ++
  s!"- L0: {pkt.fbs.L0_}\n" ++
  s!"- H0: {pkt.fbs.H0_}\n" ++
  s!"- Q0: {pkt.fbs.Q0_}\n" ++
  s!"- chi_0: {pkt.fbs.chi_0}\n\n" ++
  s!"**Initial State:**\n" ++
  s!"- phi0: {pkt.phi0}\n" ++
  s!"- deltaPhi0: {pkt.deltaPhi0}\n" ++
  s!"- t0: {pkt.t0}\n"

/-- Render a TranslationPacket as Markdown. -/
def translationPacketToMd (pkt : Translation.TranslationPacket) : String :=
  s!"# TranslationPacket Export\n\n" ++
  s!"**Analogy ID:** {pkt.analogyId}\n\n" ++
  s!"**Claim Class:** {pkt.claimClass}\n\n" ++
  s!"**Operator ID:** {pkt.operatorId}\n\n" ++
  s!"**Owner Module:** {pkt.ownerModule}\n\n" ++
  s!"**Validation Target:** {pkt.validationTarget}\n\n" ++
  s!"**Provenance:** {pkt.provenance}\n\n" ++
  s!"**Parameters:** {pkt.parameters}\n"

/-- Render core constants as Markdown. -/
def constantsToMd : String :=
  s!"# SpiralCore Constants (v14.1)\n\n" ++
  s!"| Symbol | Value | Class |\n" ++
  s!"|--------|-------|-------|\n" ++
  s!"| DIM | {DIM} | [POL] |\n" ++
  s!"| tau | {tau} | [DEF] |\n" ++
  s!"| g | {g} | [DEF] |\n" ++
  s!"| L0 | {L0} | [DEF] |\n" ++
  s!"| H0 | {H0} | [DEF] |\n" ++
  s!"| Q0 | {Q0} | [DEF] |\n" ++
  s!"| thetaEmit | {thetaEmit} | [POL] |\n" ++
  s!"| epsilonDrift | {epsilonDrift} | [POL] |\n" ++
  s!"| xiAmplitude | {xiAmplitude} | [POL] |\n" ++
  s!"| tauBase | {tauBase} | [POL] |\n" ++
  s!"| cvcThresh | {cvcThresh} | [POL] |\n" ++
  s!"| bWeightMax | {bWeightMax} | [POL] |\n" ++
  s!"| kInv | {kInv} | [POL] |\n" ++
  s!"| pdvLimit | {pdvLimit} | [POL] |\n" ++
  s!"| phiGain | {phiGain} | [POL] |\n" ++
  s!"| phiDecay | {phiDecay} | [POL] |\n" ++
  s!"| peCritical | {peCritical} | [POL] |\n" ++
  s!"| cathedralThresh | {cathedralThresh} | [POL] |\n" ++
  s!"| omegaMax | {omegaMax} | [POL] |\n" ++
  s!"| instructionFloor | {instructionFloor} | [POL] |\n" ++
  s!"| ultraBinderLimit | {ultraBinderLimit} | [DEF] |\n" ++
  s!"| tortuosityCrit | {tortuosityCrit} | [POL] |\n"

/-- Example export of the default boot packet. -/
def exampleExport : String :=
  bootPacketToMd Boot.defaultBootPacket ++ "\n" ++
  translationPacketToMd Translation.defaultPacket ++ "\n" ++
  constantsToMd

end SpiralCore.Export
