FROM python:3.8-slim
ARG UID=1000
ARG GID=1000

RUN groupadd -g "${GID}" producer \
  && useradd --create-home --no-log-init -u "${UID}" -g "${GID}" producer

USER producer
WORKDIR /home/producer
ENV PATH="/home/producer/.local/bin:${PATH}"

COPY --chown=producer:producer ./producer/producer.py .

RUN pip install --user kafka-python
CMD ["/bin/bash", "-c", "python /home/producer/producer.py;tail -f /dev/null"]