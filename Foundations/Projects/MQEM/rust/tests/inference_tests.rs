use mqem::inference::ParticleFilter;
use mqem::observation::ObservationModel;
use mqem::types::{DispersalEdge, HabitatGraph, ModelConfig, ObservationRecord};
use mqem::weighting::MultiScaleWeighter;

#[test]
fn test_observation_log_likelihood() {
    let bernoulli = ObservationModel::BernoulliOccupancy {
        detection_probability: 0.8,
    };
    let ll_present = bernoulli.log_likelihood(1.0, 2.0);
    let ll_absent = bernoulli.log_likelihood(0.0, 2.0);
    assert!(ll_present.is_finite());
    assert!(ll_absent.is_finite());
    assert!(ll_present < 0.0);

    let gaussian = ObservationModel::GaussianIndex { std_dev: 1.0 };
    let ll_gauss = gaussian.log_likelihood(2.0, 2.0);
    assert!(ll_gauss.is_finite());
}

#[test]
fn test_multiscale_weighting_normalization() {
    let weighter = MultiScaleWeighter::new(vec![1.0, 10.0, 100.0], 0.75);
    let weights = weighter.compute_normalized_weights(0.0);
    let sum: f64 = weights.iter().sum();
    assert!((sum - 1.0).abs() < 1e-6, "Weights must sum to 1.0");
    assert_eq!(weights.len(), 3);
}

#[test]
fn test_particle_filter_estimation() {
    let edges = vec![DispersalEdge {
        source: 0,
        target: 1,
        weight: 0.1,
    }];
    let graph = HabitatGraph::new(2, edges);
    let config = ModelConfig::default();
    let obs_model = ObservationModel::BernoulliOccupancy {
        detection_probability: 0.8,
    };

    let pf = ParticleFilter::new(20, config, obs_model);
    let observations = vec![
        vec![
            ObservationRecord {
                node_id: 0,
                time_step: 0,
                value: 1.0,
            },
            ObservationRecord {
                node_id: 1,
                time_step: 0,
                value: 0.0,
            },
        ],
        vec![
            ObservationRecord {
                node_id: 0,
                time_step: 1,
                value: 1.0,
            },
            ObservationRecord {
                node_id: 1,
                time_step: 1,
                value: 1.0,
            },
        ],
    ];

    let mut rng = rand::thread_rng();
    let log_lik = pf.estimate_log_likelihood(&graph, &observations, &mut rng);
    assert!(log_lik.is_finite(), "Particle filter log-likelihood must be finite");
}
