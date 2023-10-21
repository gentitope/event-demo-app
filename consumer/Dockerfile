FROM python:3.8-slim
ARG UID=1000
ARG GID=1000

RUN groupadd -g "${GID}" consumer \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" consumer

USER consumer
WORKDIR /home/consumer
ENV PATH="/home/consumer/.local/bin:${PATH}"

COPY --chown=consumer:consumer ./consumer/consumer.py .

RUN pip install --user kafka-python
CMD ["python", "/home/consumer/consumer.py"]