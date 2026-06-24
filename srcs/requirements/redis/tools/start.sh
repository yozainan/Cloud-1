#!/bin/bash
set -e

apt-get update
apt-get install -y redis-server procps && rm -rf /var/lib/apt/lists/*

sed -i 's/^supervised no/supervised systemd/' /etc/redis/redis.conf

apt-get clean
rm -rf /var/lib/apt/lists/*
