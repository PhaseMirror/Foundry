from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
import numpy as np
from genesis_governance.types import SurfaceState, MultiSubstrateState

class PerturbationFamily(ABC):
    def __init__(self, target_substrate: Optional[str] = None):
        self.target_substrate = target_substrate

    @property
    @abstractmethod
    def name(self) -> str:
        pass

    @abstractmethod
    def apply(self, state: SurfaceState, t: float) -> SurfaceState:
        pass

class AmplitudeRamp(PerturbationFamily):
    def __init__(self, ramp_rate: float, target_substrate: Optional[str] = None):
        super().__init__(target_substrate)
        self.ramp_rate = ramp_rate

    @property
    def name(self) -> str:
        return "amplitude_ramp"

    def apply(self, state: SurfaceState, t: float) -> SurfaceState:
        if self.target_substrate and state.substrate != self.target_substrate:
            return state
        new_stress = state.effective_stress * (1.0 + self.ramp_rate * t)
        return state.model_copy(update={"effective_stress": new_stress})

class DragSpike(PerturbationFamily):
    def __init__(self, spike_time: float, magnitude: float, target_substrate: Optional[str] = None):
        super().__init__(target_substrate)
        self.spike_time = spike_time
        self.magnitude = magnitude

    @property
    def name(self) -> str:
        return "drag_spike"

    def apply(self, state: SurfaceState, t: float) -> SurfaceState:
        if self.target_substrate and state.substrate != self.target_substrate:
            return state
        if abs(t - self.spike_time) < 0.1:
            new_drag = state.kinematic_drag + self.magnitude
            return state.model_copy(update={"kinematic_drag": new_drag})
        return state

class ContradictionInflation(PerturbationFamily):
    def __init__(self, inflation_rate: float, target_substrate: Optional[str] = None):
        super().__init__(target_substrate)
        self.inflation_rate = inflation_rate

    @property
    def name(self) -> str:
        return "contradiction_inflation"

    def apply(self, state: SurfaceState, t: float) -> SurfaceState:
        if self.target_substrate and state.substrate != self.target_substrate:
            return state
        new_stress = state.effective_stress * (1.0 + self.inflation_rate * t)
        return state.model_copy(update={"effective_stress": new_stress})

class FrequencyShift(PerturbationFamily):
    def __init__(self, shift_rate: float, target_substrate: Optional[str] = None):
        super().__init__(target_substrate)
        self.shift_rate = shift_rate

    @property
    def name(self) -> str:
        return "frequency_shift"

    def apply(self, state: SurfaceState, t: float) -> SurfaceState:
        if self.target_substrate and state.substrate != self.target_substrate:
            return state
        new_freq = state.frequency * (1.0 + self.shift_rate * t)
        return state.model_copy(update={"frequency": new_freq})

class CouplingPerturbation(ABC):
    """
    Base class for perturbations targeting MultiSubstrateState coupling.
    """
    @abstractmethod
    def apply_to_multi(self, multi_state: MultiSubstrateState, t: float) -> MultiSubstrateState:
        pass

class CouplingWeightSpike(CouplingPerturbation):
    def __init__(self, spike_time: float, magnitude: float, from_sub: str, to_sub: str):
        self.spike_time = spike_time
        self.magnitude = magnitude
        self.from_sub = from_sub
        self.to_sub = to_sub

    def apply_to_multi(self, multi_state: MultiSubstrateState, t: float) -> MultiSubstrateState:
        if abs(t - self.spike_time) < 0.1:
            new_matrix = multi_state.coupling_matrix.copy()
            if self.from_sub in new_matrix:
                new_row = new_matrix[self.from_sub].copy()
                new_row[self.to_sub] = new_row.get(self.to_sub, 1.0) + self.magnitude
                new_matrix[self.from_sub] = new_row
            return multi_state.model_copy(update={"coupling_matrix": new_matrix})
        return multi_state

class TimingJitter(PerturbationFamily):
    """
    Simulates stochastic variations in perturbation timing or signal arrival.
    """
    def __init__(self, jitter_amplitude: float, target_substrate: Optional[str] = None, seed: Optional[int] = None):
        super().__init__(target_substrate)
        self.jitter_amplitude = jitter_amplitude
        self.rng = np.random.default_rng(seed)

    @property
    def name(self) -> str:
        return "timing_jitter"

    def apply(self, state: SurfaceState, t: float) -> SurfaceState:
        if self.target_substrate and state.substrate != self.target_substrate:
            return state
        # Jitter manifests as a phase-like shift in the current effective stress
        # or a temporary spike representing a 'mis-timed' trigger
        jitter = self.rng.uniform(-self.jitter_amplitude, self.jitter_amplitude)
        new_stress = state.effective_stress + jitter
        return state.model_copy(update={"effective_stress": max(0.0, new_stress)})

class ThresholdNoise(PerturbationFamily):
    """
    Simulates thermal-like drift or noise on the switching threshold itself.
    """
    def __init__(self, noise_amplitude: float, target_substrate: Optional[str] = None, seed: Optional[int] = None):
        super().__init__(target_substrate)
        self.noise_amplitude = noise_amplitude
        self.rng = np.random.default_rng(seed)

    @property
    def name(self) -> str:
        return "threshold_noise"

    def apply(self, state: SurfaceState, t: float) -> SurfaceState:
        if self.target_substrate and state.substrate != self.target_substrate:
            return state
        if state.switching_threshold is None:
            return state
            
        noise = self.rng.normal(0, self.noise_amplitude)
        new_th = state.switching_threshold + noise
        return state.model_copy(update={"switching_threshold": max(0.0, new_th)})

class CyclicStress(PerturbationFamily):
    """
    Models periodic stress cycles, canonical for Metallurgical Fatigue.
    S_eff(t) = S0 * |sin(omega * t + phase)|
    """
    def __init__(
        self, 
        amplitude: float, 
        frequency: float, 
        phase: float = 0.0, 
        target_substrate: Optional[str] = None
    ):
        super().__init__(target_substrate)
        self.amplitude = amplitude
        self.frequency = frequency
        self.phase = phase

    @property
    def name(self) -> str:
        return "cyclic_stress"

    def apply(self, state: SurfaceState, t: float) -> SurfaceState:
        if self.target_substrate and state.substrate != self.target_substrate:
            return state
        new_stress = abs(self.amplitude * np.sin(self.frequency * t + self.phase))
        return state.model_copy(update={"effective_stress": new_stress})
