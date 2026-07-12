"""Parameter-only API adapter for the official Runpod ComfyUI worker."""

from copy import deepcopy
import json
import os
from pathlib import Path
import secrets


TEMPLATE_PATH = Path(
    os.environ.get("WORKFLOW_TEMPLATE_PATH", Path(__file__).with_name("api-workflow.json"))
)
with TEMPLATE_PATH.open("r", encoding="utf-8") as template_file:
    WORKFLOW_TEMPLATE = json.load(template_file)


def _dimension(value, name):
    if isinstance(value, bool) or not isinstance(value, int):
        raise ValueError(f"{name} must be an integer")
    if value < 512 or value > 1536 or value % 64 != 0:
        raise ValueError(f"{name} must be between 512 and 1536 and divisible by 64")
    return value


def build_workflow(job_input):
    """Build one single-image workflow from the public API parameters."""
    if not isinstance(job_input, dict):
        raise ValueError("input must be an object")

    positive_prompt = job_input.get("positive_prompt")
    if not isinstance(positive_prompt, str) or not positive_prompt.strip():
        raise ValueError("positive_prompt must be a non-empty string")
    if len(positive_prompt) > 10_000:
        raise ValueError("positive_prompt is too long")

    width = _dimension(job_input.get("width", 1024), "width")
    height = _dimension(job_input.get("height", 1280), "height")

    seed = job_input.get("seed")
    if seed is None:
        seed = secrets.randbelow(2**63)
    if isinstance(seed, bool) or not isinstance(seed, int) or not 0 <= seed < 2**63:
        raise ValueError("seed must be an integer between 0 and 2^63-1")

    workflow = deepcopy(WORKFLOW_TEMPLATE)
    workflow["5"]["inputs"]["text"] = positive_prompt.strip()
    workflow["7"]["inputs"].update(
        {"width": width, "height": height, "batch_size": 1}
    )
    workflow["8"]["inputs"]["seed"] = seed
    return workflow


def handler(event):
    """Translate the compact API request and delegate execution to Runpod's worker."""
    try:
        job_input = event.get("input") if isinstance(event, dict) else None
        workflow = build_workflow(job_input)
    except ValueError as exc:
        return {"error": str(exc)}

    delegated_event = dict(event)
    delegated_event["input"] = {"workflow": workflow}

    from worker_comfyui_handler import handler as comfyui_handler

    return comfyui_handler(delegated_event)


if __name__ == "__main__":
    import runpod

    runpod.serverless.start({"handler": handler})
