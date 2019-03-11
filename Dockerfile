# CosBench - https://github.com/intel-cloud/cosbench
# -----------

# Pull base image
FROM openjdk:8-jre-stretch

ENV COSBENCH_VERSION="0.4.2.c4" COSBENCH_DIR="/tmp/cosbench"

RUN apt-get update && apt-get install -y dnsutils procps bmon openjdk-8-jre apt-utils curl unzip netcat-openbsd && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN . /etc/profile && curl --retry 5 -Ls "https://github.com/intel-cloud/cosbench/releases/download/v${COSBENCH_VERSION}/${COSBENCH_VERSION}.zip" > /tmp/cosbench.zip && \
    cd /tmp ; unzip -q /tmp/cosbench.zip && \
    mv "/tmp/${COSBENCH_VERSION}" ${COSBENCH_DIR} && \
    rm /tmp/cosbench.zip && apt-get autoremove -y && \
    chmod +x ${COSBENCH_DIR}/cli.sh

# Add -N or netcat never terminates and startup fails
RUN sed -i -e 's/TOOL_PARAMS=""/TOOL_PARAMS="-N"/g' ${COSBENCH_DIR}/cosbench-start.sh

# Evil bodge to keep the container running (start-all.sh exits after starting in background). If it's the controller being started tail -f at the end (never exists)
RUN sed -i -e 's/cat $BOOT_LOG/if [ "$SERVICE_NAME" = "controller" ]; then tail -f $BOOT_LOG; else cat $BOOT_LOG; fi/g' ${COSBENCH_DIR}/cosbench-start.sh

# Run with your custom java options, change this before using
RUN sed -i -e 's/java/java YOUR_CUSTOM_FLAGS_HERE/g' ${COSBENCH_DIR}/cosbench-start.sh

EXPOSE 18088 18089 19088 19089

WORKDIR $COSBENCH_DIR

CMD cd $COSBENCH_DIR; sh ./start-all.sh
