# Qiime2 Tutorial
Learning how to use Qiime2.

### Requirements
Using a Windows machine so used Docker to run pipeline.
* Docker

### Getting Started
```bash
docker build . -t qiime_tut:latest
docker run -it --rm -v /$PWD:/qiime_tut qiime_tut -c 2 -np
```

### Sources
1. https://docs.qiime2.org/2022.11/tutorials/moving-pictures/
