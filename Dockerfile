FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    git wget libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

# pin numpy<2 to avoid torch incompatibility, pin gradio 3.x for old API
RUN pip3 install --no-cache-dir "numpy<2" \
    && pip3 install --no-cache-dir -r requirements.txt \
    && python basicsr/setup.py develop \
    && pip3 install --no-cache-dir "gradio==3.50.2"

# bake pretrained models into image so nothing downloads at runtime
RUN python scripts/download_pretrained_models.py facelib \
    && python scripts/download_pretrained_models.py CodeFormer

# copy HF Space app.py to root
RUN cp /app/web-demos/hugging_face/app.py /app/app.py

# patch app.py to bind 0.0.0.0
RUN sed -i 's/demo\.launch([^)]*)/demo.launch(server_name="0.0.0.0", server_port=7860)/' /app/app.py

EXPOSE 7860

CMD ["python", "app.py"]