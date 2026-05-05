FROM ghcr.io/onixldlc/codeformer:base AS assets
FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

RUN pip3 install --no-cache-dir "numpy<2" \
    && pip3 install --no-cache-dir -r requirements.txt \
    && python basicsr/setup.py develop \
    && pip3 install --no-cache-dir "gradio==3.50.2" "jinja2==3.1.2" "starlette==0.27.0"

# copy baked models + examples from base image
COPY --from=assets /weights/ /app/CodeFormer/weights/
COPY --from=assets /examples/01.png /app/01.png
COPY --from=assets /examples/02.jpg /app/02.jpg
COPY --from=assets /examples/03.jpg /app/03.jpg
COPY --from=assets /examples/04.jpg /app/04.jpg
COPY --from=assets /examples/05.jpg /app/05.jpg

# use patched app.py
RUN cp /app/web-demos/hugging_face/app.py /app/app.py

EXPOSE 7860

CMD ["python", "app.py"]