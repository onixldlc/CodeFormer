FROM pytorch/pytorch:2.1.0-cuda12.1-cudnn8-runtime

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

RUN pip3 install --no-cache-dir "numpy<2" \
    && pip3 install --no-cache-dir -r requirements.txt \
    && python basicsr/setup.py develop \
    && pip3 install --no-cache-dir "gradio==3.50.2" "jinja2==3.1.2" "starlette==0.27.0"

# Download model weights
RUN mkdir -p CodeFormer/weights/CodeFormer CodeFormer/weights/facelib CodeFormer/weights/realesrgan \
    && wget -q --tries=3 --waitretry=5 -O CodeFormer/weights/CodeFormer/codeformer.pth \
         https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/codeformer.pth \
    && wget -q --tries=3 --waitretry=5 -O CodeFormer/weights/facelib/detection_Resnet50_Final.pth \
         https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/detection_Resnet50_Final.pth \
    && wget -q --tries=3 --waitretry=5 -O CodeFormer/weights/facelib/parsing_parsenet.pth \
         https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/parsing_parsenet.pth \
    && wget -q --tries=3 --waitretry=5 -O CodeFormer/weights/realesrgan/RealESRGAN_x2plus.pth \
         https://github.com/sczhou/CodeFormer/releases/download/v0.1.0/RealESRGAN_x2plus.pth

# Download example images
RUN wget -q --tries=3 --waitretry=5 -O /app/01.png \
        "https://replicate.com/api/models/sczhou/codeformer/files/fa3fe3d1-76b0-4ca8-ac0d-0a925cb0ff54/06.png" \
    && wget -q --tries=3 --waitretry=5 -O /app/02.jpg \
        "https://replicate.com/api/models/sczhou/codeformer/files/a1daba8e-af14-4b00-86a4-69cec9619b53/04.jpg" \
    && wget -q --tries=3 --waitretry=5 -O /app/03.jpg \
        "https://replicate.com/api/models/sczhou/codeformer/files/542d64f9-1712-4de7-85f7-3863009a7c3d/03.jpg" \
    && wget -q --tries=3 --waitretry=5 -O /app/04.jpg \
        "https://replicate.com/api/models/sczhou/codeformer/files/a11098b0-a18a-4c02-a19a-9a7045d68426/010.jpg" \
    && wget -q --tries=3 --waitretry=5 -O /app/05.jpg \
        "https://replicate.com/api/models/sczhou/codeformer/files/7cf19c2c-e0cf-4712-9af8-cf5bdbb8d0ee/012.jpg"

# use patched app.py
RUN cp /app/web-demos/hugging_face/app.py /app/app.py

EXPOSE 7860

CMD ["python", "app.py"]