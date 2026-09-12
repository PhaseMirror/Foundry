import azure.functions as func
import json
import math
import os
import concurrent.futures

app = func.FunctionApp()

LAMBDA_M     = math.log(10)
RENORM_ALPHA = 1.0 / (2 * math.pi)
CONSENSUS_THRESHOLD = 0.30  # max deviation from median before dissent flag

SYSTEM_PROMPT = """You are the FZS-MK Memory Kernel — a Functorial Zeno Sheaf with Memory Kernel.

You will receive a list of token entries, each with pre-computed prime-harmonic weights.
For each token, apply semantic memory modulation and return a bias value in [-1.0, 1.0].

Ontology (ADR-SHF-001):
- monster_group_memory_kernel: stabilization via Monster group actions
- semantic_inertia: mass-like field property at each prime coordinate
- sheaf_morphism: structure-preserving transformation between sheaf objects

For each token entry {"id": p, "index": i, "w": w_p, "pos": pos_i}:
- base_bias = tanh(lambda_m * w_p + pos_i * renorm_alpha)
- Apply Monster group stabilization: modulate by cos(2*pi*w_p) to encode group periodicity
- Final: bias = tanh(base_bias * (1 + 0.1 * cos(2*pi*w_p)))
- Each token MUST have a distinct bias value

Return ONLY valid JSON: {"bias": [float, float, ...]} with exactly one float per token.
No explanation. No markdown."""

SYSTEM_PROMPT_NANO = """You are a bias calculator. For each token entry in the input list, compute one float bias value.

Formula for each token {"id": p, "index": i, "w": w_p, "pos": pos_i}:
  bias = tanh(lambda_m * w_p + pos_i * renorm_alpha)

Rules:
- Output MUST be a JSON object: {"bias": [float, ...]}
- One float per token, in order
- All values in [-1.0, 1.0]
- Higher w_p = higher bias magnitude
- No explanation, no markdown, no extra keys"""


def deterministic_bias(token_ids):
    n = len(token_ids)
    return [
        max(-1.0, min(1.0, math.tanh(
            LAMBDA_M * (1.0 / (abs(p) + 1)) +
            ((i - n / 2.0) / max(n, 1)) * RENORM_ALPHA
        )))
        for i, p in enumerate(token_ids)
    ]


def query_model(client, deployment, tokens, n):
    """Query a single model and return bias vector."""
    user_message = json.dumps({
        "tokens": tokens,
        "lambda_m": LAMBDA_M,
        "renorm_alpha": RENORM_ALPHA,
        "expected_bias_count": n
    })
    supports_json_format = deployment in ["gpt-4o", "gpt-5.4-nano"]

    prompt = SYSTEM_PROMPT_NANO if deployment == "gpt-5.4-nano" else SYSTEM_PROMPT

    # gpt-5.4-nano uses max_completion_tokens; others use max_tokens
    if deployment == "gpt-5.4-nano":
        kwargs = {
            "model": deployment,
            "messages": [
                {"role": "system", "content": prompt},
                {"role": "user",   "content": user_message}
            ],
            "temperature": 0.0,
            "max_completion_tokens": 512,
            "response_format": {"type": "json_object"},
        }
    else:
        kwargs = {
            "model": deployment,
            "messages": [
                {"role": "system", "content": prompt},
                {"role": "user",   "content": user_message}
            ],
            "temperature": 0.0,
            "max_tokens": 512,
        }
        if supports_json_format:
            kwargs["response_format"] = {"type": "json_object"}

    # MoonshotAI (Kimi) and DeepSeek live on helix-hammy-test endpoint
    non_openai = ["DeepSeek-V3.2"]
    if deployment in non_openai:
        from openai import AzureOpenAI as AzureOpenAIHammy
        hammy_endpoint = os.environ.get("AZURE_HAMMY_ENDPOINT", "https://helix-hammy-test.cognitiveservices.azure.com")
        hammy_key      = os.environ.get("AZURE_HAMMY_KEY", "")
        hammy_client = AzureOpenAIHammy(
            azure_endpoint=hammy_endpoint,
            api_key=hammy_key,
            api_version="2024-08-01-preview"
        )
        response = hammy_client.chat.completions.create(**kwargs)
        content = response.choices[0].message.content
    else:
        response = client.chat.completions.create(**kwargs)
        content = response.choices[0].message.content

    if content is None:
        raise ValueError(f"{deployment} returned None content")

    content = content.strip()
    if content.startswith("```"):
        content = content.split("```")[1]
        if content.startswith("json"):
            content = content[4:]
    result = json.loads(content)
    bias = result.get("bias", [0.0] * n)
    if len(bias) != n or len(set(round(b, 6) for b in bias)) == 1:
        bias = deterministic_bias([t["id"] for t in tokens])
    return [max(-1.0, min(1.0, float(b))) for b in bias]


def median_bias(vectors):
    """Compute per-token median across model vectors."""
    n = len(vectors[0])
    result = []
    for i in range(n):
        vals = sorted(v[i] for v in vectors)
        mid = len(vals) // 2
        result.append(vals[mid] if len(vals) % 2 else (vals[mid-1] + vals[mid]) / 2)
    return result


def dissent_flags(vectors, consensus, threshold, models):
    """Return list of models that deviate > threshold from consensus."""
    flags = []
    for model, vec in zip(models, vectors):
        max_dev = max(abs(v - c) for v, c in zip(vec, consensus))
        if max_dev > threshold:
            flags.append({"model": model, "max_deviation": round(max_dev, 4)})
    return flags


@app.route(route="memory", auth_level=func.AuthLevel.FUNCTION)
def memory(req: func.HttpRequest) -> func.HttpResponse:
    try:
        body = req.get_json()
        token_ids = body.get("token_ids", [])

        if not token_ids:
            return func.HttpResponse(
                json.dumps({"bias": [], "consensus_reached": True, "dissent": []}),
                mimetype="application/json", status_code=200
            )

        n = len(token_ids)
        tokens = []
        for i, p in enumerate(token_ids):
            w_p = 1.0 / (abs(p) + 1)
            pos = (i - n / 2.0) / max(n, 1)
            tokens.append({"id": p, "index": i, "w": round(w_p, 8), "pos": round(pos, 8)})

        from openai import AzureOpenAI
        endpoint = os.environ["AZURE_OPENAI_ENDPOINT"]
        api_key  = os.environ["AZURE_OPENAI_KEY"]

        client = AzureOpenAI(
            azure_endpoint=endpoint,
            api_key=api_key,
            api_version="2024-08-01-preview"
        )

        deployments = ["gpt-4o", "gpt-5.4-nano", "DeepSeek-V3.2"]

        # Query all three models in parallel
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
            futures = {
                executor.submit(query_model, client, d, tokens, n): d
                for d in deployments
            }
        # Use GPT-4o as canonical bias — DeepSeek and nano validate consensus
        model_results = {}
        errors = []
        for future in concurrent.futures.as_completed(futures):
            model = futures[future]
            try:
                model_results[model] = future.result()
            except Exception as e:
                errors.append({"model": model, "error": str(e)})
                model_results[model] = deterministic_bias(token_ids)

        # Order vectors to match deployments list
        vectors = [model_results.get(d, deterministic_bias(token_ids)) for d in deployments]

        # Canonical bias = GPT-4o output
        canonical = model_results.get("gpt-4o", deterministic_bias(token_ids))

        # Consensus = DeepSeek agrees with GPT-4o within threshold
        deepseek_vec = model_results.get("DeepSeek-V3.2", None)
        if deepseek_vec:
            primary_max_dev = max(abs(canonical[i] - deepseek_vec[i]) for i in range(len(canonical)))
            primary_agree = primary_max_dev <= CONSENSUS_THRESHOLD
        else:
            primary_agree = False

        consensus = canonical
        dissent   = dissent_flags(vectors, consensus, CONSENSUS_THRESHOLD, deployments)
        consensus_reached = primary_agree

        return func.HttpResponse(
            json.dumps({
                "bias":             consensus,
                "consensus_reached": consensus_reached,
                "dissent":          dissent,
                "models":           deployments,
                "errors":           errors,
            }),
            mimetype="application/json",
            status_code=200
        )

    except Exception as e:
        try:
            token_ids = req.get_json().get("token_ids", [])
            bias = deterministic_bias(token_ids)
            return func.HttpResponse(
                json.dumps({"bias": bias, "consensus_reached": False,
                            "dissent": [], "error": str(e), "model": "deterministic_fallback"}),
                mimetype="application/json", status_code=200
            )
        except Exception:
            return func.HttpResponse(str(e), status_code=500)
