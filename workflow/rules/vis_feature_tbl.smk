import os


rule vis_feature_table_summarize_seq:
    """
    The feature-table summarize command will give you information on:
        * How many sequences are associated with each sample and with each feature
        * Histograms of those distributions
        * Related summary statistics.
    """
    input:
        feature_table=rules.denoise_deblur_seqs.output.table_deblur,
        metadata=rules.download_sample_metadata.output,
    output:
        os.path.join("data", "qc", "table.qzv"),
    log:
        "logs/vis_feature_table_summ_seq.log",
    shell:
        """
        qiime feature-table summarize \
        --i-table {input.feature_table} \
        --o-visualization {output} \
        --m-sample-metadata-file {input.metadata} &> {log}
        """


rule vis_feature_table_id_2_seq:
    """
    The feature-table tabulate-seqs command will provide:
        * A mapping of feature IDs to sequences
        * Links to easily BLAST each sequence against the NCBI nt database.

    Useful later in the tutorial, when you want to learn more about specific features that are important in the data set.
    """
    input:
        rules.denoise_deblur_seqs.output.rep_seqs_deblur,
    output:
        os.path.join("data", "qc", "rep-seqs.qzv"),
    log:
        "logs/vis_feature_table_id_2_seq.log",
    shell:
        """
        qiime feature-table tabulate-seqs \
        --i-data {input} \
        --o-visualization {output} &> {log}
        """


rule vis_feature_tbl_all:
    input:
        rules.vis_feature_table_summarize_seq.output,
        rules.vis_feature_table_id_2_seq.output,
