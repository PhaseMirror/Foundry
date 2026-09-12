import { useEffect, useRef } from 'react';
import cytoscape from 'cytoscape';

interface TensorTopographyProps {
  resonance: number; // R in [0.0, 1.0]
  stabilityMetric?: number;
}

export const TensorTopography = ({ resonance, stabilityMetric = 0.5 }: TensorTopographyProps) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const cyRef = useRef<cytoscape.Core | null>(null);

  // Multiplicity formula: M(R) = 2R + 1 (Multiplicity.SocioAtomic in Lean 4)
  const multiplicityM = 2.0 * resonance + 1.0;

  useEffect(() => {
    if (!containerRef.current) return;

    // Initialize Cytoscape with Layer 6 Socio-Atomic Particles and Layer 7 Shells
    cyRef.current = cytoscape({
      container: containerRef.current,
      elements: [
        // NUCLEUS: Protons (Core Individuals / Identity)
        { data: { id: 'p1', label: 'Proton α (Agent)', type: 'proton', role: 'nucleus' } },
        { data: { id: 'p2', label: 'Proton β (Counsel)', type: 'proton', role: 'nucleus' } },

        // NUCLEUS: Neutrons (Civic Infrastructure / WORM Ledger)
        { data: { id: 'n1', label: 'Neutron 1 (WORM Anchor)', type: 'neutron', role: 'nucleus' } },
        { data: { id: 'n2', label: 'Neutron 2 (CRMF Ledger)', type: 'neutron', role: 'nucleus' } },

        // VALENCE SHELL: Electrons (Dynamic Participants / Sensors)
        { data: { id: 'e1', label: 'e⁻ (Custodian ESI)', type: 'electron', role: 'orbital' } },
        { data: { id: 'e2', label: 'e⁻ (Sidecar Stream)', type: 'electron', role: 'orbital' } },
        { data: { id: 'e3', label: 'e⁻ (Auditor Node)', type: 'electron', role: 'orbital' } },

        // Nuclear Strong-Force Bonds (Internal Cohesion)
        { data: { id: 'n_bond1', source: 'p1', target: 'n1', kind: 'nuclear' } },
        { data: { id: 'n_bond2', source: 'p2', target: 'n2', kind: 'nuclear' } },
        { data: { id: 'n_bond3', source: 'p1', target: 'p2', kind: 'nuclear' } },
        { data: { id: 'n_bond4', source: 'n1', target: 'n2', kind: 'nuclear' } },

        // Multiplicity Resonance Exchange: M(R) = 2R + 1
        { data: { id: 'orb1', source: 'p1', target: 'e1', kind: 'resonance' } },
        { data: { id: 'orb2', source: 'p2', target: 'e2', kind: 'resonance' } },
        { data: { id: 'orb3', source: 'n1', target: 'e3', kind: 'resonance' } },
        { data: { id: 'orb4', source: 'e1', target: 'e2', kind: 'orbital_coupling' } },
        { data: { id: 'orb5', source: 'e2', target: 'e3', kind: 'orbital_coupling' } },
      ],
      style: [
        // Protons: Vibrant Gold/Amber
        {
          selector: 'node[type = "proton"]',
          style: {
            'background-color': '#f59e0b',
            'label': 'data(label)',
            'color': '#fef3c7',
            'font-size': '10px',
            'font-family': 'JetBrains Mono, monospace',
            'text-valign': 'top',
            'text-halign': 'center',
            'width': 26,
            'height': 26,
            'border-width': 2,
            'border-color': '#fbbf24',
          }
        },
        // Neutrons: Deep Emerald (Stability)
        {
          selector: 'node[type = "neutron"]',
          style: {
            'background-color': '#10b981',
            'label': 'data(label)',
            'color': '#d1fae5',
            'font-size': '10px',
            'font-family': 'JetBrains Mono, monospace',
            'text-valign': 'top',
            'text-halign': 'center',
            'width': 26,
            'height': 26,
            'border-width': 2,
            'border-color': '#34d399',
          }
        },
        // Electrons: Cyan/Indigo Orbitals
        {
          selector: 'node[type = "electron"]',
          style: {
            'background-color': '#06b6d4',
            'label': 'data(label)',
            'color': '#cffafe',
            'font-size': '9px',
            'font-family': 'JetBrains Mono, monospace',
            'text-valign': 'bottom',
            'text-halign': 'center',
            'width': 18,
            'height': 18,
            'border-width': 1,
            'border-color': '#67e8f9',
          }
        },
        // Nuclear Strong-Force Bonds
        {
          selector: 'edge[kind = "nuclear"]',
          style: {
            'width': 3,
            'line-color': 'rgba(245, 158, 11, 0.7)',
            'curve-style': 'bezier',
          }
        },
        // Multiplicity Resonance Exchange Lines
        {
          selector: 'edge[kind = "resonance"]',
          style: {
            'width': 2,
            'line-color': 'rgba(16, 185, 129, 0.6)',
            'line-style': 'dashed',
            'curve-style': 'bezier',
          }
        },
        // Orbital Valence Coupling
        {
          selector: 'edge[kind = "orbital_coupling"]',
          style: {
            'width': 1,
            'line-color': 'rgba(6, 182, 212, 0.4)',
            'curve-style': 'bezier',
          }
        }
      ],
      layout: {
        name: 'concentric',
        concentric: (node: any) => node.data('role') === 'nucleus' ? 2 : 1,
        levelWidth: () => 1,
        padding: 35,
        animate: true,
      },
      userZoomingEnabled: false,
      userPanningEnabled: false,
    });

    return () => {
      cyRef.current?.destroy();
    };
  }, []);

  // Animate dynamic bond thickness and orbital coupling based on M(R) = 2R + 1
  useEffect(() => {
    if (!cyRef.current) return;
    const cy = cyRef.current;

    const bondWidth = Math.max(1, Math.round(multiplicityM * 1.5));
    const resonanceAlpha = Math.min(1.0, 0.3 + (resonance * 0.7));

    cy.edges('[kind = "resonance"]').animate({
      style: {
        'width': bondWidth,
        'line-color': `rgba(16, 185, 129, ${resonanceAlpha})`,
      }
    }, { duration: 300 });

    cy.nodes('[type = "proton"]').animate({
      style: {
        'width': Math.round(20 + resonance * 10),
        'height': Math.round(20 + resonance * 10),
      }
    }, { duration: 300 });

  }, [resonance, multiplicityM]);

  return (
    <div style={{ width: '100%', position: 'relative' }}>
      <div 
        style={{ 
          width: '100%', 
          height: '320px',
          position: 'relative',
          zIndex: 10
        }} 
        ref={containerRef} 
      />
      <div style={{
        position: 'absolute',
        bottom: '8px',
        right: '12px',
        fontSize: '11px',
        color: '#10b981',
        fontFamily: 'JetBrains Mono, monospace',
        background: 'rgba(0,0,0,0.6)',
        padding: '4px 8px',
        borderRadius: '4px',
        border: '1px solid rgba(16, 185, 129, 0.3)',
        zIndex: 20
      }}>
        M(R) = 2({resonance.toFixed(2)}) + 1 = {multiplicityM.toFixed(2)} (Layer 6 Verified)
      </div>
    </div>
  );
};


