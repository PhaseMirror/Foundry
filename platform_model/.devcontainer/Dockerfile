FROM docker.io/library/docker:28.4.0-cli@sha256:6a73c9433f2ba4279815be1e60f5739288b939dda1e48151d8c393537802de37 AS docker_cli
FROM docker.io/library/golang:1.19.7-alpine3.17@sha256:04065e607052705ede1ac6308ce56aec4715b0fafb1f0c2f4c2333aab9d84442 AS upstream_oracles
COPY standards/oracles/oci-distribution-1.1.1 /src/distribution
COPY standards/oracles/oci-runtime-1.3.0 /src/runtime
COPY standards/oracles/oci-image-1.1.1 /src/image
RUN cd /src/distribution \
    && CGO_ENABLED=0 go test -c -o /oci-distribution-conformance --ldflags='-X github.com/opencontainers/distribution-spec/conformance.Version=a139cc423184af6078077b9b7ee336eddbd03f8f' \
    && cd /src/runtime \
    && CGO_ENABLED=0 go build -trimpath -o /oci-runtime-validate ./validate.go \
    && cd /src/image \
    && CGO_ENABLED=0 go test -c -o /oci-image-schema-conformance ./schema
FROM docker.io/library/golang:1.23.8-alpine3.21@sha256:b7486658b87d34ecf95125e5b97e8dfe86c21f712aa36fc0c702e5dc41dc63e1 AS cloudevents_oracle
COPY standards/oracles/cloudevents-sdk-go-2.16.2 /src/cloudevents
COPY sdk/oracles/go/cloudevents-validator /src/wrapper
RUN cd /src/cloudevents/v2 \
    && CGO_ENABLED=0 go test -c -o /cloudevents-sdk-conformance ./event \
    && cd /src/wrapper \
    && go mod edit -replace github.com/cloudevents/sdk-go/v2=/src/cloudevents/v2 \
    && CGO_ENABLED=0 go build -trimpath -o /cloudevents-validator .
FROM docker.io/library/maven:3.9.11-eclipse-temurin-21@sha256:6fdc855a6ed81d288ca7ca37ac6ff5e9308b612485c0801d70b25a858c83d237 AS openid_oracle
COPY standards/oracles/openid-conformance-suite-3e09b13b /src/openid
RUN cd /src/openid \
    && mvn --batch-mode --quiet \
      -Dmaven.gitcommitid.skip=true \
      -Djacoco.skip=true \
      -Dtest=ValidateIdTokenSignature_UnitTest,OIDCCValidateRequestObjectExp_UnitTest,CheckDiscEndpointIssuer_UnitTest,CheckDiscEndpointIssuerIsValidUrl_UnitTest \
      test
RUN find /root/.m2/repository -type f \( -name '*.lastUpdated' -o -name '_remote.repositories' -o -name 'resolver-status.properties' -o -name 'maven-metadata-*.xml' -o -name 'maven-metadata-*.xml.sha1' \) -delete \
    && rm -f /src/openid/target/classes/META-INF/build-info.properties /src/openid/target/classes/git.properties \
    && find /root/.m2/repository /src/openid/target/classes /src/openid/target/test-classes -exec touch -h -d '@0' '{}' +
FROM docker.io/library/debian:bookworm-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171

COPY --from=docker_cli /usr/local/bin/docker /usr/local/bin/docker

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    ELAN_HOME=/usr/local/elan \
    PATH=/usr/local/cargo/bin:/usr/local/elan/bin:$PATH

RUN apt-get update \
    && apt-get install --no-install-recommends --yes \
        build-essential ca-certificates coreutils=9.1-1 curl git libgmp10 \
        libssl-dev pkg-config ripgrep xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSfL \
        https://static.rust-lang.org/rustup/archive/1.28.2/x86_64-unknown-linux-gnu/rustup-init \
        -o /tmp/rustup-init \
    && echo "20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c  /tmp/rustup-init" | sha256sum -c - \
    && chmod +x /tmp/rustup-init \
    && /tmp/rustup-init -y --no-modify-path --profile minimal --default-toolchain 1.97.1 \
    && rm /tmp/rustup-init \
    && rustup component add rustfmt clippy rust-analyzer \
    && rustup target add wasm32-unknown-unknown

RUN curl --proto '=https' --tlsv1.2 -sSfL \
        https://nodejs.org/dist/v22.23.2/node-v22.23.2-linux-x64.tar.xz \
        -o /tmp/node.tar.xz \
    && echo "d60acfe00a2932254bb0ad20e01b0d74397a0875595de719654b214f4b03f307  /tmp/node.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/node.tar.xz --strip-components=1 -C /usr/local \
    && rm /tmp/node.tar.xz \
    && node --version \
    && npm --version

RUN cargo install --locked wasm-bindgen-cli --version 0.2.122 \
    && cargo install --locked wasm-tools --version 1.258.0 \
    && cargo install --locked wasmtime-cli --version 48.0.1 \
    && cargo install --locked cargo-local-registry --version 0.2.12

RUN curl -sSfL https://github.com/leanprover/elan/releases/download/v4.2.3/elan-x86_64-unknown-linux-gnu.tar.gz -o elan.tar.gz \
    && echo "df0b2b3a439961ffcbb3985214365ffe40f49bc871df04dff268c7d8e21ca8b2  elan.tar.gz" | sha256sum -c - \
    && mkdir -p /tmp/elan-bin && tar -xzf elan.tar.gz -C /tmp/elan-bin \
    && /tmp/elan-bin/elan-init -y --no-modify-path --default-toolchain none \
    && rm -rf elan.tar.gz /tmp/elan-bin \
    && elan toolchain install leanprover/lean4:v4.32.1

RUN curl -sSfL https://github.com/casey/just/releases/download/1.57.0/just-1.57.0-x86_64-unknown-linux-musl.tar.gz -o just.tar.gz \
    && echo "45b548094283cb9739af8f13273b8cddeee869f5b4ef2bb631b1f311cb566155  just.tar.gz" | sha256sum -c - \
    && tar -xzf just.tar.gz -C /usr/local/bin just \
    && rm just.tar.gz \
    && chmod +x /usr/local/bin/just

RUN curl -sSfL https://github.com/EmbarkStudios/cargo-deny/releases/download/0.20.2/cargo-deny-0.20.2-x86_64-unknown-linux-musl.tar.gz -o cargo-deny.tar.gz \
    && echo "9f12ed4c49936e09b48bf862b595cde2fe64fcbd9d74dfacac6131ca824c8d5f  cargo-deny.tar.gz" | sha256sum -c - \
    && tar -xzf cargo-deny.tar.gz --strip-components=1 -C /usr/local/bin cargo-deny-0.20.2-x86_64-unknown-linux-musl/cargo-deny \
    && rm cargo-deny.tar.gz \
    && chmod +x /usr/local/bin/cargo-deny

COPY --from=docker_cli /usr/local/libexec/docker/cli-plugins/docker-buildx /usr/local/libexec/docker/cli-plugins/docker-buildx
COPY --from=upstream_oracles --chmod=0755 /oci-distribution-conformance /usr/local/bin/oci-distribution-conformance
COPY --from=upstream_oracles --chmod=0755 /oci-runtime-validate /usr/local/bin/oci-runtime-validate
COPY --from=upstream_oracles --chmod=0755 /oci-image-schema-conformance /usr/local/bin/oci-image-schema-conformance
COPY --from=cloudevents_oracle --chmod=0755 /cloudevents-sdk-conformance /usr/local/bin/cloudevents-sdk-conformance
COPY --from=cloudevents_oracle --chmod=0755 /cloudevents-validator /usr/local/bin/cloudevents-validator
COPY --from=openid_oracle /usr/share/maven /opt/prismpm/openid-maven
COPY --from=openid_oracle /opt/java/openjdk /opt/prismpm/openid-java
COPY --from=openid_oracle /root/.m2/repository /opt/prismpm/openid-m2
COPY --from=openid_oracle /src/openid/target/classes /opt/prismpm/openid-target/classes
COPY --from=openid_oracle /src/openid/target/test-classes /opt/prismpm/openid-target/test-classes
COPY --chmod=0755 sdk/oracles/openid-conformance.sh /usr/local/bin/openid-conformance

RUN git config --system --add safe.directory /workspaces/PrismPM

COPY --chmod=0755 .devcontainer/docker-entrypoint.sh /usr/local/bin/prismpm-devcontainer-init

RUN groupadd --gid 1000 vscode \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash vscode \
    && mkdir -p /home/vscode/.cargo/bin \
    && mkdir -p /home/vscode/.elan/tmp \
    && for binary in /usr/local/cargo/bin/*; do ln -s "$binary" "/home/vscode/.cargo/bin/$(basename "$binary")"; done \
    && ln -s /usr/local/elan/bin /home/vscode/.elan/bin \
    && ln -s /usr/local/elan/toolchains /home/vscode/.elan/toolchains \
    && chown -R vscode:vscode /home/vscode

ENV CARGO_HOME=/home/vscode/.cargo \
    ELAN_HOME=/home/vscode/.elan

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/prismpm-devcontainer-init"]
CMD ["sleep", "infinity"]
