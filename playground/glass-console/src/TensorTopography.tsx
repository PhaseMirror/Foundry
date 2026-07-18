import { useEffect, useRef, useState } from 'react';
import cytoscape from 'cytoscape';

interface TensorTopographyProps {
  stabilityMetric: number;
}

export const TensorTopography = ({ stabilityMetric }: TensorTopographyProps) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const cyRef = useRef<cytoscape.Core | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    // Initialize Cytoscape
    cyRef.current = cytoscape({
      container: containerRef.current,
      elements: [
        { data: { id: 'p2', label: 'p2 (HRV)' } },
        { data: { id: 'p3', label: 'p3 (EEG)' } },
        { data: { id: 'p5', label: 'p5' } },
        { data: { id: 'p7', label: 'p7 (GSR / Entropy)' } },
        
        { data: { id: 'e1', source: 'p2', target: 'p3' } },
        { data: { id: 'e2', source: 'p3', target: 'p5' } },
        { data: { id: 'e3', source: 'p5', target: 'p7' } },
        { data: { id: 'e4', source: 'p7', target: 'p2' } },
      ],
      style: [
        {
          selector: 'node',
          style: {
            'background-color': '#8b5cf6',
            'label': 'data(label)',
            'color': '#f8fafc',
            'text-valign': 'top',
            'text-halign': 'center',
            'font-size': '12px',
            'font-family': 'JetBrains Mono, monospace',
            'width': 20,
            'height': 20,
          }
        },
        {
          selector: 'edge',
          style: {
            'width': 2,
            'line-color': 'rgba(139, 92, 246, 0.4)',
            'curve-style': 'bezier'
          }
        }
      ],
      layout: {
        name: 'circle',
        padding: 40,
        animate: true,
      },
      userZoomingEnabled: false,
      userPanningEnabled: false,
    });

    return () => {
      cyRef.current?.destroy();
    };
  }, []);

  useEffect(() => {
    if (!cyRef.current) return;

    const cy = cyRef.current;
    
    // Animate the network based on the stability metric
    const isStable = stabilityMetric >= 0.05;
    
    const nodeColor = isStable ? '#10b981' : '#f43f5e'; // Success green vs Danger red
    const edgeColor = isStable ? 'rgba(16, 185, 129, 0.5)' : 'rgba(244, 63, 94, 0.5)';

    cy.nodes().animate({
      style: {
        'background-color': nodeColor
      }
    }, { duration: 300 });

    cy.edges().animate({
      style: {
        'line-color': edgeColor,
        'width': isStable ? 2 : 4
      }
    }, { duration: 300 });

    // Apply a jitter to simulate dissonance if not stable
    if (!isStable) {
      cy.nodes().forEach(node => {
        node.animate({
          position: {
            x: node.position('x') + (Math.random() - 0.5) * 20,
            y: node.position('y') + (Math.random() - 0.5) * 20
          }
        }, { duration: 500 });
      });
    } else {
      cy.layout({ name: 'circle', animate: true, animationDuration: 500 }).run();
    }

  }, [stabilityMetric]);

  return (
    <div 
      style={{ 
        width: '100%', 
        height: '300px',
        position: 'relative',
        zIndex: 10
      }} 
      ref={containerRef} 
    />
  );
};
