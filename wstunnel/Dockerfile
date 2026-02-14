ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_ARCH

# Install dependencies
RUN apk add --no-cache jq curl tar

# Dynamically resolve architecture and fetch the latest wstunnel release
RUN if [ "${BUILD_ARCH}" = "aarch64" ]; then \
      WST_ARCH="linux_arm64"; \
    elif [ "${BUILD_ARCH}" = "amd64" ]; then \
      WST_ARCH="linux_amd64"; \
    elif [ "${BUILD_ARCH}" = "i386" ]; then \
      WST_ARCH="linux_386"; \      
    elif [ "${BUILD_ARCH}" = "armhf" ] || [ "${BUILD_ARCH}" = "armv7" ]; then \
      WST_ARCH="linux_armv7"; \
    else \
      WST_ARCH="linux_amd64"; \
    fi && \
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/erebe/wstunnel/releases/latest | jq -r ".assets[] | select(.name | contains(\"${WST_ARCH}.tar.gz\")) | .browser_download_url") && \
    curl -L "$DOWNLOAD_URL" -o wstunnel.tar.gz && \
    tar -xzf wstunnel.tar.gz && \
    mv wstunnel /usr/local/bin/wstunnel && \
    rm wstunnel.tar.gz && \
    chmod +x /usr/local/bin/wstunnel

# Copy and set execution permissions for the runner
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]