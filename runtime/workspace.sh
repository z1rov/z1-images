#!/usr/bin/env bash

Z1_WORKSPACE="${Z1_WORKSPACE:-/workspace}"

mkdir -p "${Z1_WORKSPACE}"
chmod -R 0777 "${Z1_WORKSPACE}"

mkdir -p /opt/tools/bin /opt/tools/src /opt/tools/forja
mkdir -p /usr/share/wordlists /usr/share/rules
