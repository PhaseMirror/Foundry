import json
import numpy as np
from pikernel.projectors import ProjectorFamily, PiIndexGrid
from pikernel.kernel import PiKernel
from pikernel.ledgerposeidon import PoseidonLedger
from pikernel.mub_audit import mub_drift_audit


def _build_kernel(n: int) -> PiKernel:
    """Build a PiKernel for n-dimensional token space."""
    # Two families: even/odd indices and lower/upper half
    mid = max(1, n // 2)
    even = [i for i in range(n) if i % 2 == 0]
    odd  = [i for i in range(n) if i % 2 != 0]
    lower = list(range(mid))
    upper = list(range(mid, n))

    # Ensure no empty families
    if not odd:   odd = even[-1:]; even = even[:-1]
    if not upper: upper = lower[-1:]; lower = lower[:-1]

    A = ProjectorFamily([even, odd], name="Parity")
    B = ProjectorFamily([lower, upper], name="Half")
    grid = PiIndexGrid([A, B])

    piids = grid.piids
    m = len(piids)

    alphas  = {pi: 0.25 for pi in piids}
    weights = {pi: np.ones(len(grid.indices(pi))) for pi in piids}
    taus    = {pi: 1.5 for pi in piids}

    # Off-diagonal coupling — guarantees SlopeUB <= 0.9
    K = 0.05 * np.ones((m, m))
    np.fill_diagonal(K, 0.0)

    return PiKernel(grid, alphas, weights, taus, K, ledger=PoseidonLedger())


def handler(event, context):
    body = json.loads(event.get('body', '{}'))
    token_ids = body.get('token_ids', [])

    if not token_ids:
        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'bias': []})
        }

    n = len(token_ids)
    x = np.array(token_ids, dtype=float)
    kernel = _build_kernel(n)
    result = kernel.step(x)
    bias = result['xnew'].tolist()

    # MUB drift audit on the state vector
    mub = mub_drift_audit(result['xnew'], threshold=3.0)

    # Poseidon ledger digest of last touched atom
    ledger_digest = None
    if kernel.ledger and len(kernel.ledger) > 0:
        ledger_digest = kernel.ledger.entries[-1].get('digest')

    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json'},
        'body': json.dumps({
            'bias': bias,
            'SlopeUB': result['SlopeUB'],
            'GapLB': result['GapLB'],
            'num_touched': result['num_touched'],
            'mub_D_t': mub['D_t'],
            'mub_alarm': mub['alarm'],
            'mub_action': mub['action'],
            'ledger_digest': ledger_digest,
            'ledger_type': 'poseidon_bn254',
        })
    }
