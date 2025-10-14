FROM docker.n8n.io/n8nio/n8n

USER root
RUN apk add --update python3 py3-pip

USER node
RUN python3 -m pip install --user --break-system-packages pipx

ENV PATH="/home/node/.local/bin:$PATH"