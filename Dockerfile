FROM uvarc/qiime2:2022.2

WORKDIR /qiime_tut

COPY requirements.txt requirements.txt

RUN pip3 install -r requirements.txt

# Set entrypoint so can run pipeline in working dir and pass cli args to snakemake.
ENTRYPOINT ["snakemake"]
