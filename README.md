Getting started
Clone project -> git clone https://github.com/keniz01/ci_cd.git
Install dependencies -> uv sync
Build docker image -> docker compose build or docker build -t web_app .
Run image -> docker compose up or docker run -d -p 8000:8000 web_app