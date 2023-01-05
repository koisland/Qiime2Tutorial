import os


rule filter_seqs:
    """
    First, an initial quality filtering process based on quality scores is applied.
    This method is an implementation of the quality filtering approach described by Bokulich et al. (2013).
    https://www.nature.com/articles/nmeth.2276
    """
    input:
        rules.demux_seqs.output.demuxed_seqs,
    output:
        filtered_seqs=os.path.join("data", "qc", "demux-filtered.qza"),
        filtered_seq_stats=os.path.join("data", "qc", "demux-filter-stats.qza"),
    log:
        "logs/filter_sequences.log",
    shell:
        """
        qiime quality-filter q-score \
        --i-demux {input} \
        --o-filtered-sequences {output.filtered_seqs} \
        --o-filter-stats {output.filtered_seq_stats} &> {log}
        """


rule denoise_deblur_seqs:
    """
    Deblur workflow is applied using the qiime deblur denoise-16S method.
    Parameter --p-trim-length n which truncates the sequences at position n.
    * In general, the Deblur developers recommend setting this value to a length where the median quality score (Q) begins to drop too low.
        * https://www.illumina.com/documents/products/technotes/technote_Q-Scores.pdf
    * On these data, the quality plots (prior to quality filtering) suggest a reasonable choice is in the 115 to 130 sequence position range.
        * https://view.qiime2.org/visualization/?type=html&src=https%3A%2F%2Fdocs.qiime2.org%2F2022.11%2Fdata%2Ftutorials%2Fmoving-pictures%2Fdemux.qzv
    * NOTE: This is a subjective assessment.
    """
    input:
        rules.filter_seqs.output.filtered_seqs,
    output:
        rep_seqs_deblur=os.path.join("data", "qc", "rep-seqs.qza"),
        table_deblur=os.path.join("data", "qc", "table.qza"),
        deblur_stats=os.path.join("data", "qc", "deblur-stats.qza"),
    params:
        trim_len=120,
    log:
        "logs/denoise_deblur.log",
    benchmark:
        "benchmarks/deblur_benchmark.tsv"
    shell:
        """
        qiime deblur denoise-16S \
        --i-demultiplexed-seqs {input} \
        --p-trim-length {params.trim_len} \
        --o-representative-sequences {output.rep_seqs_deblur} \
        --o-table {output.table_deblur} \
        --p-sample-stats \
        --o-stats {output.deblur_stats} &> {log}
        """


rule vis_filter_seqs:
    """
    Summary stats about output of filtering sequences based on quality.
    """
    input:
        rules.filter_seqs.output.filtered_seq_stats,
    output:
        os.path.join("data", "qc", "demux-filter-stats.qzv"),
    shell:
        """
        qiime metadata tabulate \
        --m-input-file {input} \
        --o-visualization {output}
        """


rule vis_denoise_deblur_seqs:
    """
    Summary stats about denoising and deblurring sequences.
    """
    input:
        rules.denoise_deblur_seqs.output.deblur_stats,
    output:
        os.path.join("data", "qc", "deblur-stats.qzv"),
    shell:
        """
        qiime deblur visualize-stats \
        --i-deblur-stats {input} \
        --o-visualization {output}
        """


rule qc_all:
    input:
        rules.filter_seqs.output,
        rules.denoise_deblur_seqs.output,
        rules.vis_filter_seqs.output,
        rules.vis_denoise_deblur_seqs.output,
    default_target: True
