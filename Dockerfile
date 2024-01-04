FROM python:3.12-slim AS builder
LABEL authors="user"
ENV USER daveisme
ENV HOME /home/$USER

RUN apt update && \
    apt upgrade --yes && \
    useradd --create-home $USER

USER $USER
WORKDIR $HOME

ENV VIRTUALENV=$HOME/.venv
ENV PATH="$VIRTUALENV/bin:$PATH"

COPY --chown=daveisme pyproject.toml constraints.txt ./
COPY --chown=daveisme src/ src/
COPY --chown=daveisme test/ test/

RUN python3 -m venv $VIRTUALENV && \
    python -m pip install --upgrade pip setuptools && \
    python -m pip install --no-cache-dir -c constraints.txt ".[dev]" && \
    python -m pip install . -c constraints.txt && \
    python -m flake8 src/ && \
    python -m isort src/ --check && \
    python -m black src/ --check --quiet && \
    python -m pylint src/ --disable=C0114,C0116,R1705 && \
    python -m bandit -r src/ --quiet && \
    python -m pip wheel --wheel-dir dist/ . -c constraints.txt

#    python -m pytest test/unit/ && \

#CMD ["flask", "--app", "page_tracker.app", "run", "--host", "0.0.0.0", "--port", "5000"]
#ENTRYPOINT ["top", "-b"]

FROM python:3.12-slim
ENV USER daveisme
ENV HOME /home/$USER

RUN apt-get update && \
    apt-get upgrade --yes && \
    useradd --create-home $USER

USER $USER
WORKDIR $HOME

ENV VIRTUALENV=$HOME/.venv
ENV PATH="$VIRTUALENV/bin:$PATH"

COPY --from=builder $HOME/dist/page_tracker*.whl $HOME

RUN python3 -m venv $VIRTUALENV && \
    python -m pip install --upgrade pip setuptools && \
    python -m pip install --no-cache-dir page_tracker*.whl

CMD ["flask", "--app", "page_tracker.app", "run", "--host", "0.0.0.0", "--port", "5000"]