FROM cybercoredev/solana:latest AS cli

FROM cybercoredev/evm_loader:latest AS spl

FROM ubuntu:20.04

COPY . /opt
WORKDIR /opt

RUN apt -y update
RUN DEBIAN_FRONTEND=noninteractive apt -y install \
                                          software-properties-common \
                                          openssl \
                                          ca-certificates \
                                          curl
RUN add-apt-repository universe
RUN apt -y install python3-pip python3-venv
RUN rm -rf /var/lib/apt/lists/*

COPY --from=cli /opt/solana/bin/solana \
                /opt/solana/bin/solana-faucet \
                /opt/solana/bin/solana-keygen \
                /opt/solana/bin/solana-validator \
                /opt/solana/bin/solana-genesis \
                /cli/bin/

COPY --from=spl /opt/evm_loader.so /spl/bin/
COPY --from=spl /opt/neon-cli* /spl/bin/

RUN python3 -m venv venv
RUN pip3 install --upgrade pip
RUN /bin/bash -c "source venv/bin/activate"
RUN ls .
RUN pip install -r requirements.txt

WORKDIR /proxy

ENV PATH /venv/bin:/cli/bin/:/spl/bin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EXPOSE 8899/tcp 9090/tcp
ENTRYPOINT [ "python3" ]
CMD [ "-m proxy --hostname 127.0.0.1 --port 9090 --enable-web-server --plugins proxy.plugin.SolanaProxyPlugin --num-workers=1" ]
