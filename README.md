# Qiime2 Tutorial
[![Tests](https://github.com/koisland/Qiime2Tutorial/actions/workflows/main.yaml/badge.svg)](https://github.com/koisland/Qiime2Tutorial/actions/workflows/main.yaml)

Following the Qiime2 tutorial for ["Moving Pictures"](https://docs.qiime2.org/2022.11/tutorials/moving-pictures/).

## Requirements
* `Docker`
    * Base image for `Dockerfile` is [`uvarc/qiime2:2022.2`](https://hub.docker.com/r/uvarc/qiime2)

## Usage
Build the image with `Snakemake` installed.
```bash
# Build the image with Snakemake. Working dir set to qiime_tut
docker build . -t qiime_tut:latest
```

Then run the pipeline.
```bash
docker run -it --rm -v /$PWD:/qiime_tut qiime_tut -c 2 -np
```

## Sources
1. https://docs.qiime2.org/2022.11/tutorials/moving-pictures/
