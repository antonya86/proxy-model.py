ARG SOLANA_REVISION=latest
ARG EVM_LOADER_REVISION=latest

FROM cybercoredev/solana:${SOLANA_REVISION} AS cli

FROM cybercoredev/evm_loader:${EVM_LOADER_REVISION} AS spl

FROM ubuntu:20.04

RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt -y install \
            software-properties-common openssl curl \
            ca-certificates python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/*

COPY ./requirements.txt /opt
COPY ./proxy/api.py.patch /opt
WORKDIR /opt

RUN python3 -m venv venv && \
    pip3 install --upgrade pip && \
    /bin/bash -c "source venv/bin/activate" && \
    pip install -r requirements.txt

COPY --from=cli /opt/solana/bin/solana \
                /opt/solana/bin/solana-faucet \
                /opt/solana/bin/solana-keygen \
                /opt/solana/bin/solana-validator \
                /opt/solana/bin/solana-genesis \
                /cli/bin/

COPY --from=spl /opt/solana/bin/solana /cli/bin/
COPY --from=spl /opt/evm_loader.so \
                /opt/neon-cli /spl/bin/
COPY --from=spl /opt/neon-cli /spl/bin/emulator

COPY . /opt
RUN patch /usr/local/lib/python3.8/dist-packages/solana/rpc/api.py /opt/api.py.patch

ENV PATH /venv/bin:/cli/bin/:/spl/bin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV SOLANA_URL="http://localhost:8899"

EXPOSE 9090/tcp
ENTRYPOINT [ "./proxy/run-proxy.sh" ]
