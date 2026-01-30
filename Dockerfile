FROM odoo:18.0 AS ocb_source

ARG OCB_REPO="https://github.com/OCA/OCB.git"
ARG OCB_REF="18.0"
ARG OCB_COMMIT=""
ARG OCB_ARCHIVE_URL="https://github.com/OCA/OCB/archive"
ARG BUILD_PROXY=""

USER root

ENV PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple \
    PIP_TRUSTED_HOST=pypi.tuna.tsinghua.edu.cn

RUN set -eux; \
    if [ -n "${BUILD_PROXY}" ]; then export http_proxy="${BUILD_PROXY}" https_proxy="${BUILD_PROXY}"; fi; \
    mkdir -p /tmp/ocb; \
    tmp_dir=$(mktemp -d); \
    archive_ref="${OCB_COMMIT:-$OCB_REF}"; \
    if [ -n "${OCB_COMMIT}" ]; then \
        archive_path="${OCB_COMMIT}"; \
    else \
        case "${OCB_REF}" in \
            refs/*) archive_path="${OCB_REF}" ;; \
            *) archive_path="refs/heads/${OCB_REF}" ;; \
        esac; \
    fi; \
    archive_base=${OCB_ARCHIVE_URL%/}; \
    archive_url="${archive_base}/${archive_path}.tar.gz"; \
    curl -fL --retry 5 --retry-all-errors --connect-timeout 20 --max-time 300 -o "${tmp_dir}/ocb.tar.gz" "${archive_url}"; \
    tar -xzf "${tmp_dir}/ocb.tar.gz" --strip-components=1 -C /tmp/ocb; \
    echo "${archive_ref}" > /tmp/ocb/.ocb_commit; \
    rm -rf "${tmp_dir}"

FROM odoo:18.0

ARG BUILD_PROXY=""

USER root

# apt 不使用代理，直接走官方源
RUN set -eux; \
    export DEBIAN_FRONTEND=noninteractive; \
    apt-get update; \
    apt-get install -y --no-install-recommends wget gnupg; \
    codename="$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')"; \
    echo "deb http://apt.postgresql.org/pub/repos/apt ${codename}-pgdg main" > /etc/apt/sources.list.d/pgdg.list; \
    wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/pgdg.gpg; \
    apt-get update; \
    apt-get install -y --no-install-recommends build-essential libpq-dev python3-venv; \
    rm -rf /var/lib/apt/lists/*

ENV VIRTUAL_ENV=/opt/ocb-venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

RUN python3 -m venv --system-site-packages "${VIRTUAL_ENV}"

COPY --from=ocb_source /tmp/ocb/requirements.txt /tmp/ocb_requirements.txt

ARG EXTRA_REQUIREMENTS_FILE=requirements.txt
COPY ${EXTRA_REQUIREMENTS_FILE} /tmp/extra_requirements.txt

RUN set -eux; \
    if [ -n "${BUILD_PROXY}" ]; then export http_proxy="${BUILD_PROXY}" https_proxy="${BUILD_PROXY}"; fi; \
    pip install --no-cache-dir -r /tmp/ocb_requirements.txt; \
    if [ -s /tmp/extra_requirements.txt ]; then \
        echo "[ocb-docker] installing extra requirements from ${EXTRA_REQUIREMENTS_FILE}"; \
        pip install --no-cache-dir -r /tmp/extra_requirements.txt; \
    else \
        echo "[ocb-docker] no extra requirements provided"; \
    fi; \
    rm -f /tmp/extra_requirements.txt

COPY --from=ocb_source /tmp/ocb /opt/ocb

RUN set -eux; \
    rm -rf /usr/lib/python3/dist-packages/odoo; \
    cp -a /opt/ocb/odoo /usr/lib/python3/dist-packages/; \
    install -m 755 /opt/ocb/odoo-bin /usr/bin/odoo-bin; \
    ln -sf /usr/bin/odoo-bin /usr/bin/odoo

USER odoo

ENV ODOO_RC=/etc/odoo/odoo.conf

EXPOSE 8069 8072

CMD ["odoo-bin"]
