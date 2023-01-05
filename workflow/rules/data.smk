import os


rule download_data:
    output:
        os.path.join("data"),
    params:
        url="",
    shell:
        """
        curl -sL {params.url} > {output}
        """


use rule download_data as download_sample_metadata with:
    output:
        os.path.join("data", "original", "sample_metadata.tsv"),
    params:
        url="https://data.qiime2.org/2022.11/tutorials/moving-pictures/sample_metadata.tsv",


use rule download_data as download_sample_seqs with:
    output:
        os.path.join(
            "data", "original", "emp-single-end-sequences", "sequences.fastq.gz"
        ),
    params:
        url="https://data.qiime2.org/2022.11/tutorials/moving-pictures/emp-single-end-sequences/sequences.fastq.gz",


use rule download_data as download_sample_barcodes with:
    output:
        os.path.join(
            "data", "original", "emp-single-end-sequences", "barcodes.fastq.gz"
        ),
    params:
        url="https://data.qiime2.org/2022.11/tutorials/moving-pictures/emp-single-end-sequences/barcodes.fastq.gz",


rule import_data_to_qza:
    """
    Import sequence data files into a QIIME 2 artifact.

    The semantic type of this QIIME 2 artifact is EMPSingleEndSequences.
    * EMPSingleEndSequences QIIME 2 artifacts contain sequences that are multiplexed and have not yet been assigned to samples.
        * barcodes.fastq.gz contains the barcode read associated with each sequence in sequences.fastq.gz.
    """
    input:
        rules.download_sample_seqs.output,
        rules.download_sample_barcodes.output,
    output:
        os.path.join("data", "original", "emp-single-end-sequences.qza"),
    log:
        "logs/import_data_to_qza.log",
    params:
        emp_seq_dir=lambda wc, input: os.path.dirname(str(input[0])),
    shell:
        """
        qiime tools import \
        --type EMPSingleEndSequences \
        --input-path {params.emp_seq_dir} \
        --output-path {output} &> {log}
        """


rule data_all:
    input:
        rules.download_sample_metadata.output,
        rules.download_sample_seqs.output,
        rules.download_sample_barcodes.output,
        rules.import_data_to_qza.output,
    default_target: True
