use mqem::laplacian::GraphSpectralAnalyzer;
use mqem::types::{DispersalEdge, HabitatGraph};

#[test]
fn test_graph_laplacian_properties() {
    let edges = vec![
        DispersalEdge {
            source: 0,
            target: 1,
            weight: 1.0,
        },
        DispersalEdge {
            source: 1,
            target: 2,
            weight: 1.0,
        },
        DispersalEdge {
            source: 2,
            target: 0,
            weight: 1.0,
        },
    ];
    let graph = HabitatGraph::new(3, edges);
    let laplacian = GraphSpectralAnalyzer::compute_laplacian(&graph);

    // Row sums must be zero
    for i in 0..3 {
        let row_sum: f64 = laplacian[i].iter().sum();
        assert!(row_sum.abs() < 1e-9, "Laplacian row sum must be zero");
    }

    // Fiedler value for a 3-cycle with unit weights is 3.0
    let fiedler = GraphSpectralAnalyzer::compute_fiedler_value(&graph);
    assert!(fiedler > 0.0, "Connected graph must have positive Fiedler value");
}

#[test]
fn test_disconnected_graph_zero_fiedler() {
    let graph = HabitatGraph::new(4, Vec::new());
    let fiedler = GraphSpectralAnalyzer::compute_fiedler_value(&graph);
    assert_eq!(fiedler, 0.0, "Disconnected graph must have zero Fiedler value");
}
