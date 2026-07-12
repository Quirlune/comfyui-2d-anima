# ComfyUI and the official Runpod queue worker.
FROM runpod/worker-comfyui:5.8.4-base

ENV WORKFLOW_TEMPLATE_PATH=/app/api-workflow.json

# Preserve the official worker and startup script, then install a small API
# adapter plus cached-model linker around them.
RUN cp /handler.py /worker_comfyui_handler.py \
    && cp /start.sh /worker-comfyui-start.sh

COPY handler.py /handler.py
COPY start-cached.sh /start-cached.sh
COPY api-workflow.json /app/api-workflow.json

RUN chmod +x /start-cached.sh

CMD ["/start-cached.sh"]
