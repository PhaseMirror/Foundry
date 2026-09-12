# syntax=docker/dockerfile:1.12@sha256:93bfd3b68c109427185cd78b4779fc82b484b0b7618e36d0f104d4d801e66d25
FROM --platform=$BUILDPLATFORM docker.io/library/node:22.23.2-bookworm-slim@sha256:83f487e0a63425e5b4d146fb5e5be574bcbe1b7b843d3ebafdd95eaf7767a7e5 AS dependencies

ARG SOURCE_DATE_EPOCH=0

WORKDIR /opt/prismpm/runtime
COPY sdk/runtime/package.json sdk/runtime/package-lock.json ./
RUN npm ci --ignore-scripts --omit=dev \
    && npm cache clean --force \
    && chmod -R a-w /opt/prismpm/runtime

FROM docker.io/library/node:22.23.2-bookworm-slim@sha256:83f487e0a63425e5b4d146fb5e5be574bcbe1b7b843d3ebafdd95eaf7767a7e5

ARG SOURCE_DATE_EPOCH=0
ENV SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH

WORKDIR /opt/prismpm/runtime
COPY --from=dependencies /opt/prismpm/runtime/node_modules ./node_modules
COPY --from=dependencies /opt/prismpm/runtime/package.json /opt/prismpm/runtime/package-lock.json ./
COPY --chmod=0555 sdk/runtime/runtime.mjs ./runtime.mjs
COPY --chmod=0444 sdk/runtime/profile.mjs ./profile.mjs

ENV NODE_ENV=production
USER node
CMD ["node", "/opt/prismpm/runtime/runtime.mjs", "help"]
