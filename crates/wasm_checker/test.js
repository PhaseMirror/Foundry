import init, { JointState, FibreState, Weights, check_contractivity } from './pkg/roc_wasm_checker.js';

async function run() {
    await init();
    const state = new JointState(
        new FibreState(1, 0, 0),
        new FibreState(0, 1, 0)
    );
    const weights = new Weights(1, 2, 3);
    console.log("Contractivity check:", check_contractivity(state, weights));
}
run();
