#############################################
#   Global ARGs ############################
##  Versions    ############################
ARG TF_VERSION=1.5.7
#
ARG TF_VSPHERE_VER=2.4.3
ARG TF_GITHUB_VER=5.38.0
ARG TF_YC_VER=0.99.0
ARG TF_LOCAL_VER=2.4.0
ARG TF_RANDOM_VER=3.5.1
#
##  Names    ###############################
ARG TF_VSPHERE=terraform-provider-vsphere
ARG TF_GITHUB=terraform-provider-github
ARG TF_YC=terraform-provider-yandex
ARG TF_LOCAL=terraform-provider-local
ARG TF_RANDOM=terraform-provider-random
#
############################################

FROM golang:1.21 as builder

#   https://github.com/hashicorp/terraform/
ARG TF_VERSION
ARG TF_SRC=https://github.com/hashicorp/terraform/archive/refs/tags/v${TF_VERSION}.zip

#   https://github.com/hashicorp/terraform-provider-vsphere/
ARG TF_VSPHERE
ARG TF_VSPHERE_VER
ARG TF_VSPHERE_SRC=https://github.com/hashicorp/${TF_VSPHERE}/archive/refs/tags/v${TF_VSPHERE_VER}.zip

#   https://github.com/integrations/terraform-provider-github/
ARG TF_GITHUB
ARG TF_GITHUB_VER
ARG TF_GITHUB_SRC=https://github.com/integrations/${TF_GITHUB}/archive/refs/tags/v${TF_GITHUB_VER}.zip

#   https://github.com/yandex-cloud/terraform-provider-yandex
ARG TF_YC
ARG TF_YC_VER
ARG TF_YC_SRC=https://github.com/yandex-cloud/${TF_YC}/archive/refs/tags/v${TF_YC_VER}.zip

#   https://github.com/hashicorp/terraform-provider-local/
ARG TF_LOCAL
ARG TF_LOCAL_VER
ARG TF_LOCAL_SRC=https://github.com/hashicorp/${TF_LOCAL}/archive/refs/tags/v${TF_LOCAL_VER}.zip

#   https://github.com/hashicorp/terraform-provider-random/
ARG TF_RANDOM
ARG TF_RANDOM_VER
ARG TF_RANDOM_SRC=https://github.com/hashicorp/${TF_RANDOM}/archive/refs/tags/v${TF_RANDOM_VER}.zip

WORKDIR /tmp

RUN go env -w GO111MODULE=auto

RUN apt update && \
    apt install unzip

ADD ${TF_SRC} ./terraform.zip
RUN unzip terraform.zip && cd terraform-${TF_VERSION} && \
    go build -o /tmp/bin/terraform && \
    cd ../

ADD ${TF_VSPHERE_SRC} ./vsphere.zip
RUN unzip vsphere.zip && cd ${TF_VSPHERE}-${TF_VSPHERE_VER} && \
    go build -o /tmp/bin/${TF_VSPHERE}_${TF_VSPHERE_VER} && \
    cd ../

ADD ${TF_GITHUB_SRC} ./github.zip
RUN unzip github.zip && cd ${TF_GITHUB}-${TF_GITHUB_VER} && \
    go build -o /tmp/bin/${TF_GITHUB}_${TF_GITHUB_VER} && \
    cd ../

ADD ${TF_YC_SRC} ./yc.zip
RUN unzip yc.zip && cd ${TF_YC}-${TF_YC_VER} && \
    go build -o /tmp/bin/${TF_YC}_${TF_YC_VER} && \
    cd ../

ADD ${TF_LOCAL_SRC} ./local.zip
RUN unzip local.zip && cd ${TF_LOCAL}-${TF_LOCAL_VER} && \
    go build -o /tmp/bin/${TF_LOCAL}_${TF_LOCAL_VER} && \
    cd ../

ADD ${TF_RANDOM_SRC} ./random.zip
RUN unzip random.zip && cd ${TF_RANDOM}-${TF_RANDOM_VER} && \
    go build -o /tmp/bin/${TF_RANDOM}_${TF_RANDOM_VER} && \
    cd ../

### build ###

FROM debian:stable

LABEL mainteiner="Dmitrii Trotskii"
LABEL email="dmitrii.trotskii@gmail.com"
LABEL function="Terraform with compiled providers"

ARG ARCH=linux_amd64

ARG TF_VSPHERE
ARG TF_VSPHERE_VER

ARG TF_GITHUB
ARG TF_GITHUB_VER

ARG TF_YC
ARG TF_YC_VER

ARG TF_LOCAL
ARG TF_LOCAL_VER

ARG TF_RANDOM
ARG TF_RANDOM_VER

ENV TF_PLUGINS_DIR=/root/.terraform.d/plugins/local

COPY --from=builder /tmp/bin/terraform /usr/sbin/
COPY --from=builder /tmp/bin/${TF_VSPHERE}_${TF_VSPHERE_VER} ${TF_PLUGINS_DIR}/hashicorp/vsphere/${TF_VSPHERE_VER}/${ARCH}/
COPY --from=builder /tmp/bin/${TF_GITHUB}_${TF_GITHUB_VER} ${TF_PLUGINS_DIR}/integrations/github/${TF_GITHUB_VER}/${ARCH}/
COPY --from=builder /tmp/bin/${TF_YC}_${TF_YC_VER} ${TF_PLUGINS_DIR}/yandex-cloud/yandex/${TF_YC_VER}/${ARCH}/
COPY --from=builder /tmp/bin/${TF_LOCAL}_${TF_LOCAL_VER} ${TF_PLUGINS_DIR}/hashicorp/local/${TF_LOCAL_VER}/${ARCH}/
COPY --from=builder /tmp/bin/${TF_RANDOM}_${TF_RANDOM_VER} ${TF_PLUGINS_DIR}/hashicorp/random/${TF_RANDOM_VER}/${ARCH}/

RUN apt update && \
    apt install -y git tree vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /terraform

RUN ln -s ${TF_PLUGINS_DIR} /terraform/plugins
