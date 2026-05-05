FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime
 
ENV DEBIAN_FRONTEND=noninteractive
 
RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev \
    && rm -rf /var/lib/apt/lists/*
 
WORKDIR /app
COPY . /app
 
RUN pip3 install --no-cache-dir -r requirements.txt \
    && python basicsr/setup.py develop
 
# download pretrained models at build time so container is self-contained
RUN python scripts/download_pretrained_models.py facelib \
    && python scripts/download_pretrained_models.py CodeFormer
 
# install gradio for web UI
RUN pip3 install --no-cache-dir gradio
 
# copy the HF Space app.py into root if not already there
RUN if [ ! -f /app/app.py ] && [ -f /app/web-demos/hugging_face/app.py ]; then \
      cp /app/web-demos/hugging_face/app.py /app/app.py; \
    fi
 
# patch app.py to bind 0.0.0.0 so docker can expose it
RUN sed -i 's/demo\.launch()/demo.launch(server_name="0.0.0.0", server_port=7860)/' /app/app.py 2>/dev/null || true \
    && sed -i 's/demo\.launch(share=True)/demo.launch(server_name="0.0.0.0", server_port=7860)/' /app/app.py 2>/dev/null || true \
    && sed -i 's/demo\.launch(share=False)/demo.launch(server_name="0.0.0.0", server_port=7860)/' /app/app.py 2>/dev/null || true
 
EXPOSE 7860
 
CMD ["python", "app.py"]
