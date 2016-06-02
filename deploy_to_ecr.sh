#!/bin/bash

`aws ecr get-login --region us-east-1` && \
docker build -t bitfinex-autorenewer . && \
docker tag bitfinex-autorenewer:latest 248022314417.dkr.ecr.us-east-1.amazonaws.com/bitfinex-autorenewer:latest && \
docker push 248022314417.dkr.ecr.us-east-1.amazonaws.com/bitfinex-autorenewer:latest
