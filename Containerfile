###############################################
# Stage 1: Frontend Build
###############################################
FROM quay.io/hummingbird/nodejs:24-builder AS frontend-builder

USER 0

WORKDIR /frontend

COPY mealie/frontend .

# Workaround HUM-1827: native addon builds need full ICU data
RUN dnf install -y nodejs24-full-i18n && dnf clean all

RUN npm install -g yarn

RUN yarn install \
    --prefer-offline \
    --frozen-lockfile \
    --non-interactive \
    --production=false \
    --network-timeout 1000000

RUN yarn generate

###############################################
# Stage 2: Backend Package Build
###############################################
FROM quay.io/hummingbird/python:3.12-builder AS backend-builder

USER 0

RUN pip install uv

WORKDIR /mealie

COPY mealie/uv.lock mealie/pyproject.toml ./
COPY mealie/mealie ./mealie

COPY --from=frontend-builder /frontend/dist ./mealie/frontend

RUN uv build --out-dir dist

RUN uv export --no-editable --no-emit-project --extra pgsql --format requirements-txt --output-file dist/requirements.txt \
    && MEALIE_VERSION=$(python3 -c "import tomllib; print(tomllib.load(open('pyproject.toml', 'rb'))['project']['version'])") \
    && echo "mealie[pgsql]==${MEALIE_VERSION} \\" >> dist/requirements.txt \
    && pip hash dist/mealie-${MEALIE_VERSION}-py3-none-any.whl | tail -n1 | tr -d '\n' >> dist/requirements.txt \
    && echo " \\" >> dist/requirements.txt \
    && pip hash dist/mealie-${MEALIE_VERSION}.tar.gz | tail -n1 >> dist/requirements.txt

###############################################
# Stage 3: Python Virtual Environment Build
###############################################
FROM quay.io/hummingbird/python:3.12-builder AS venv-builder

USER 0

ENV VENV_PATH="/opt/mealie"

RUN dnf install -y --setopt=install_weak_deps=False \
    gcc \
    gcc-c++ \
    make \
    python3.12-devel \
    openldap-devel \
    cyrus-sasl-devel \
    && dnf clean all

RUN python3 -m venv --upgrade-deps $VENV_PATH

COPY --from=backend-builder /mealie/dist /dist/

RUN . $VENV_PATH/bin/activate \
    && pip install --require-hashes -r /dist/requirements.txt --find-links /dist

ENV NLTK_DATA="/nltk_data/"
RUN mkdir -p $NLTK_DATA \
    && $VENV_PATH/bin/python -m nltk.downloader -d $NLTK_DATA averaged_perceptron_tagger_eng

###############################################
# Stage 4: Production
###############################################
FROM quay.io/hummingbird/python:3.12 AS production

ENV MEALIE_HOME="/app" \
    VENV_PATH="/opt/mealie" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PRODUCTION=true \
    TESTING=false \
    APP_PORT=9000 \
    HOST=0.0.0.0

ENV PATH="$VENV_PATH/bin:$PATH"

ARG COMMIT
ENV GIT_COMMIT_HASH=$COMMIT

COPY --from=venv-builder --chown=65532:0 $VENV_PATH $VENV_PATH

ENV NLTK_DATA="/nltk_data/"
COPY --from=venv-builder --chown=65532:0 $NLTK_DATA $NLTK_DATA

# Runtime shared libraries for python-ldap (only native module built from source;
# psycopg2-binary and Pillow bundle their own libs).
COPY --from=venv-builder /usr/lib64/libldap.so* /usr/lib64/
COPY --from=venv-builder /usr/lib64/liblber.so* /usr/lib64/
COPY --from=venv-builder /usr/lib64/libsasl2.so* /usr/lib64/
COPY --from=venv-builder /usr/lib64/sasl2/ /usr/lib64/sasl2/
COPY --from=venv-builder /usr/lib64/libevent-2.1.so* /usr/lib64/
# libstdc++: needed by pillow-heif's bundled libheif
COPY --from=venv-builder /usr/lib64/libstdc++.so.6* /usr/lib64/

WORKDIR $MEALIE_HOME

COPY --chown=65532:0 docker/entrypoint.py $MEALIE_HOME/entrypoint.py
COPY --chown=65532:0 docker/healthcheck.py $MEALIE_HOME/healthcheck.py

VOLUME ["$MEALIE_HOME/data/"]

EXPOSE ${APP_PORT}

HEALTHCHECK CMD ["python3", "/app/healthcheck.py"]

ENTRYPOINT ["python3", "/app/entrypoint.py"]
