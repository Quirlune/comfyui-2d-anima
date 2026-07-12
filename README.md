# 2D ANIMA Serverless API

Queue-based Runpod Serverless worker for the original ComfyUI workflow.

The endpoint accepts a compact parameter object and always generates one image per job. Configure Runpod with `Active workers = 0` and `Max workers = 1` so simultaneous jobs queue behind one GPU worker instead of scaling to multiple GPUs.

## Request

```json
{
  "input": {
    "positive_prompt": "a cinematic portrait by a window",
    "width": 1024,
    "height": 1280,
    "seed": 42
  }
}
```

- `positive_prompt`: required string.
- `width`, `height`: optional; default to `1024 × 1280`, range `512–1536`, divisible by 64.
- `seed`: optional integer. A random seed is generated when omitted.
- One job always uses `batch_size = 1`.

Call `POST https://api.runpod.ai/v2/<ENDPOINT_ID>/run` for queued asynchronous jobs or `/runsync` for a blocking request.

## Cached models

Set the endpoint Model field to the private Hugging Face repository and add:

```text
HF_MODEL_ID=<user>/comfyui-2d-anima-models
```

The startup script locates the Runpod cached snapshot under `/runpod-volume/huggingface-cache/hub/` and links the five model files into their ComfyUI directories.

## Endpoint settings

- Endpoint type: Queue-based
- Active workers: 0
- Max workers: 1
- Idle timeout: 5 seconds
- FlashBoot: enabled
- GPU priority: RTX 4090 PRO, then RTX 5090
- GPUs per worker: 1
