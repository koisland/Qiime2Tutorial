import os


rule demux_seqs:
    """
    Demultiplex sequences.
        * Need to know which barcode sequence (sample metadata) is associated with each sample.
        * The demux emp-single command refers to the fact that:
            * These sequences are barcoded according to the Earth Microbiome Project protocol
            * Are single-end reads.
    Output:
        * The demux.qza QIIME 2 artifact will contain the demultiplexed sequences.
        * The second output (demux-details.qza) presents Golay error correction details.
    """
    input:
        emp_single_end_seqs=rules.import_data_to_qza.output,
        metadata_file=rules.download_sample_metadata.output,
    output:
        demuxed_seqs=os.path.join("data", "demux", "demux.qza"),
        err_corr_details=os.path.join("data", "demux", "demux-details.qza"),
    params:
        barcode_col="barcode-sequence",
    log:
        os.path.join("logs", "demux_seqs.log"),
    shell:
        """
        qiime demux emp-single \
        --i-seqs {input.emp_single_end_seqs} \
        --m-barcodes-file {input.metadata_file} \
        --m-barcodes-column {params.barcode_col} \
        --o-per-sample-sequences {output.demuxed_seqs} \
        --o-error-correction-details {output.err_corr_details} &> {log}
        """


rule demux_seqs_summary:
    """
    Summarize the demultiplexing results.
    This allows you to:
        * Determine how many sequences were obtained per sample
        * Get a summary of the distribution of sequence qualities at each position in your sequence data.
    """
    input:
        rules.demux_seqs.output.demuxed_seqs,
    output:
        os.path.join("data", "demux", "demux.qzv"),
    log:
        os.path.join("logs", "demux", "demux_summary.log"),
    shell:
        """
        qiime demux summarize \
        --i-data {input} \
        --o-visualization {output} &> {log}
        """


rule demux_all:
    input:
        rules.demux_seqs.output,
        rules.demux_seqs_summary.output,
    default_target: True
