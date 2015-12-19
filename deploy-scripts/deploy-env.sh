#!/usr/bin/env bash

export SSH_OPTS=""
export DEPLOY_USER=root

export REGISTRY_PUB_IP=1.2.3.4

export AGENT_01_PUB_IP=1.2.3.4
export AGENT_02_PUB_IP=1.2.3.4
export AGENT_03_PUB_IP=1.2.3.4

export GAME_01_PUB_IP=1.2.3.4
export GAME_02_PUB_IP=1.2.3.4

export SNOWFLAKE_PUB_IP=1.2.3.4
export ARCHIVER_PUB_IP=1.2.3.4

export MONITOR_PUB_IP=1.2.3.4

export registry_do="ssh ${SSH_OPTS} ${DEPLOY_USER}@${REGISTRY_PUB_IP}"

export agent_01_do="ssh ${SSH_OPTS} ${DEPLOY_USER}@${AGENT_01_PUB_IP}"
export agent_02_do="ssh ${SSH_OPTS} ${DEPLOY_USER}@${AGENT_02_PUB_IP}"
export agent_03_do="ssh ${SSH_OPTS} ${DEPLOY_USER}@${AGENT_03_PUB_IP}"

export game_01_do="ssh ${SSH_OPTS} ${DEPLOY_USER}@${GAME_01_PUB_IP}"
export game_02_do="ssh ${SSH_OPTS} ${DEPLOY_USER}@${GAME_02_PUB_IP}"

export snowflake_do="ssh ${SSH_OPTS} ${DEPLOY_USER}@${SNOWFLAKE_PUB_IP}"
export archiver_do="ssh ${SSH_OPTS} ${DEPLOY_USER}@${ARCHIVER_PUB_IP}"

export monitor_do="ssh ${SSH_OPTS} ${DEPLOY_USER}@${MONITOR_PUB_IP}"
