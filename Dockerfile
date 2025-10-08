# syntax=docker/dockerfile:1

FROM odoo:18.0 AS ocb_source

ARG OCB_REPO="https://github.com/OCA/OCB.git"
ARG OCB_REF="18.0"
ARG OCB_COMMIT=""

USER root

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends git ca-certificates curl; \
    rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    git clone --depth=1 --branch "${OCB_REF}" "${OCB_REPO}" /tmp/ocb; \
    if [ -n "${OCB_COMMIT}" ]; then \
        git -C /tmp/ocb fetch origin "${OCB_COMMIT}" --depth=1 || git -C /tmp/ocb fetch origin "${OCB_COMMIT}"; \
        git -C /tmp/ocb checkout "${OCB_COMMIT}"; \
    fi; \
    git -C /tmp/ocb rev-parse HEAD > /tmp/ocb/.ocb_commit; \
    rm -rf /tmp/ocb/.git

FROM odoo:18.0

USER root

COPY --from=ocb_source /tmp/ocb/requirements.txt /tmp/ocb_requirements.txt

RUN python3 -m pip install --no-cache-dir -r /tmp/ocb_requirements.txt

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

