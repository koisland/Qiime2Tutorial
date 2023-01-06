
rule calc_core_metrics_phylo:
    """
    Apply the core-metrics-phylogenetic method, which:
        * Rarefies a FeatureTable[Frequency] to a user-specified depth
        * Computes several alpha and beta diversity metrics
            * Alpha diversity
                * Shannon's diversity index (a quantitative measure of community richness)
                * Observed Features (a qualitative measure of community richness)
                * Faith's Phylogenetic Diversity (a qualitative measure of community richness that incorporates phylogenetic relationships between the features)
                * Evenness (or Pielou's Evenness; a measure of community evenness)
            Beta diversity
                * Jaccard distance (a qualitative measure of community dissimilarity)
                * Bray-Curtis distance (a quantitative measure of community dissimilarity)
                * unweighted UniFrac distance (a qualitative measure of community dissimilarity that incorporates phylogenetic relationships between the features)
                * weighted UniFrac distance (a quantitative measure of community dissimilarity that incorporates phylogenetic relationships between the features)
        * Generates principle coordinates analysis (PCoA) plots using Emperor for each of the beta diversity metrics.
    """
    input:
        rooted_tree=rules.generate_phylogeny_tree.output.rooted_tree,
        sample_metadata=rules.download_sample_metadata.output,
        table_deblur=rules.denoise_deblur_seqs.output.table_deblur,
    output:
        # Artifacts
        faith_pd_vector=os.path.join(
            "output", "core-metrics-results", "faith_pd_vector.qza"
        ),
        unweighted_unifrac_distance_matrix=os.path.join(
            "output", "core-metrics-results", "unweighted_unifrac_distance_matrix.qza"
        ),
        bray_curtis_pcoa_results=os.path.join(
            "output", "core-metrics-results", "bray_curtis_pcoa_results.qza"
        ),
        shannon_vector=os.path.join(
            "output", "core-metrics-results", "shannon_vector.qza"
        ),
        rarefied_table=os.path.join(
            "output", "core-metrics-results", "rarefied_table.qza"
        ),
        weighted_unifrac_distance_matrix=os.path.join(
            "output", "core-metrics-results", "weighted_unifrac_distance_matrix.qza"
        ),
        jaccard_pcoa_results=os.path.join(
            "output", "core-metrics-results", "jaccard_pcoa_results.qza"
        ),
        weighted_unifrac_pcoa_results=os.path.join(
            "output", "core-metrics-results", "weighted_unifrac_pcoa_results.qza"
        ),
        observed_features_vector=os.path.join(
            "output", "core-metrics-results", "observed_features_vector.qza"
        ),
        jaccard_distance_matrix=os.path.join(
            "output", "core-metrics-results", "jaccard_distance_matrix.qza"
        ),
        evenness_vector=os.path.join(
            "output", "core-metrics-results", "evenness_vector.qza"
        ),
        bray_curtis_distance_matrix=os.path.join(
            "output", "core-metrics-results", "bray_curtis_distance_matrix.qza"
        ),
        unweighted_unifrac_pcoa_results=os.path.join(
            "output", "core-metrics-results", "unweighted_unifrac_pcoa_results.qza"
        ),
        # Visualizations
        unweighted_unifrac_emperor=os.path.join(
            "output", "core-metrics-results", "unweighted_unifrac_emperor.qzv"
        ),
        jaccard_emperor=os.path.join(
            "output", "core-metrics-results", "jaccard_emperor.qzv"
        ),
        bray_curtis_emperor=os.path.join(
            "output", "core-metrics-results", "bray_curtis_emperor.qzv"
        ),
        weighted_unifrac_emperor=os.path.join(
            "output", "core-metrics-results", "weighted_unifrac_emperor.qzv"
        ),
    params:
        # For the DADA2 feature table...
        # How many samples will be excluded from your analysis based on this choice?
        # * 3
        # How many total sequences will you be analyzing in the core-metrics-phylogenetic command?
        # * 34,193?
        # I used the Deblur feature table and decided on 723. This cuts off 3 samples.
        # * These are right palm samples
        # Retained 22,413 (21.85%) features in 31 (91.18%) samples at the specifed sampling depth.
        p_sampling_depth=723,
        output_dir=lambda wc, output: os.path.dirname(output[0]),
    threads: workflow.cores
    log:
        "logs/diversity_analysis.log",
    shell:
        """
        # Warning: Remove directory Snakemake automatically makes. Qiime2 errors if already exists.
        rm -rf {params.output_dir}

        qiime diversity core-metrics-phylogenetic \
        --i-phylogeny {input.rooted_tree} \
        --i-table {input.table_deblur} \
        --p-sampling-depth {params.p_sampling_depth} \
        --m-metadata-file {input.sample_metadata} \
        --p-n-jobs-or-threads {threads} \
        --output-dir {params.output_dir} &> {log}
        """


rule check_alpha_grp_signif:
    """
    Test for associations between categorical metadata columns and alpha diversity data.
    Using:
        * Faith Phylogenetic Diversity (a measure of community richness)
            * Which categorical sample metadata columns are most strongly associated with the differences in microbial community richness?
                * Body site
            * Are these differences statistically significant?
                * Yes they are. p = 0.0003511787904591362
        * Evenness metrics. (or Pielou's Evenness; a measure of community evenness)
            * Which categorical sample metadata columns are most strongly associated with the differences in microbial community evenness?
                * Body site
            * Are these differences statistically significant?
                * Yes they are. p = 0.018405441632345393
    """
    input:
        sample_metadata=rules.download_sample_metadata.output,
        alpha_div_vec=os.path.join(
            "output", "core-metrics-results", "{alpha_div_metric}_vector.qza"
        ),
    output:
        alpha_div_signif=os.path.join(
            "output",
            "core-metrics-results",
            "{alpha_div_metric}-group-significance.qzv",
        ),
    log:
        "logs/alpha_grp_signif_{alpha_div_metric}.log",
    shell:
        """
        qiime diversity alpha-group-significance \
        --i-alpha-diversity {input.alpha_div_vec} \
        --m-metadata-file {input.sample_metadata} \
        --o-visualization {output.alpha_div_signif} &> {log}
        """


rule check_beta_grp_signif:
    """
    Test whether distances between samples within a group, such as samples from the same body site (e.g., gut), are more similar to each other then they are to samples from the other groups.
        * Using PERMANOVA
            * https://cscu.cornell.edu/workshop/introduction-to-permanova/
            * https://www.researchgate.net/post/What_is_the_purpose_of_a_Permanova_test_specifically_in_terms_of_the_gut_microbiota
            * Based on pseudo-F:
                * https://forum.qiime2.org/t/pseudo-f-ratio-in-permanova-test/10413
        * (e.g., tongue, left palm, and right palm).
    The --p-pairwise parameter will also perform pairwise tests that will allow you to determine which specific pairs of groups (e.g., tongue and gut) differ from one another, if any.

    Are the associations between subjects and differences in microbial composition statistically significant?
        * No. p = 0.538
    How about body sites?
        * Yes. p = 0.001
    What specific pairs of body sites are significantly different from each other?
        * gut-(l_palm, r_palm, tongue)
        * l_palm-tongue
        * r_palm-tongue
    """
    input:
        sample_metadata=rules.download_sample_metadata.output,
        unwt_unifrac_dst_mtx=rules.calc_core_metrics_phylo.output.unweighted_unifrac_distance_matrix,
    output:
        os.path.join(
            "output",
            "core-metrics-results",
            "unweighted-unifrac-{metadata_col}-significance.qzv",
        ),
    log:
        "logs/beta_grp_signif_{metadata_col}.log",
    params:
        pairwise_cmp="--p-pairwise",
    shell:
        """
        qiime diversity beta-group-significance \
        --i-distance-matrix {input.unwt_unifrac_dst_mtx} \
        --m-metadata-file {input.sample_metadata} \
        --m-metadata-column {wildcards.metadata_col} \
        --o-visualization {output} \
        {params.pairwise_cmp}
        """


rule plot_ord_emperor:
    """
    Use the Emperor tool to explore principal coordinates (PCoA) plots in the context of sample metadata.
        * unweighted UniFrac
        * Bray-Curtis
    Resulting plot will contain axes for principal coordinate 1, principal coordinate 2, and days since the experiment start.
        * We will use that last axis to explore how these samples changed over time

    Do the Emperor plots support the other beta diversity analyses we've performed here?
        * From beta_grp_signif:
            * gut-(l_palm, r_palm, tongue)
            * l_palm-tongue
            * r_palm-tongue
        * There is a clear separation in the above body site clusters based.
            * Slightly better with bray-curtis as dissimiliarity beta-diversity metric.
    What differences do you observe between the unweighted UniFrac and Bray-Curtis PCoA plots?
        * Axis 2 using unweighted UnifFrac does not separate L/R palm and tongue as cleanly.
    """
    input:
        sample_metadata=rules.download_sample_metadata.output,
        beta_div_metric_res=os.path.join(
            "output", "core-metrics-results", "{beta_div_metric}_pcoa_results.qza"
        ),
    output:
        os.path.join(
            "output",
            "core-metrics-results",
            "{beta_div_metric}-emperor-days-since-experiment-start.qzv",
        ),
    params:
        additional_axis="days-since-experiment-start",
    shell:
        """
        qiime emperor plot \
        --i-pcoa {input.beta_div_metric_res} \
        --m-metadata-file {input.sample_metadata} \
        --p-custom-axes {params.additional_axis} \
        --o-visualization {output}
        """


# rule plot_alpha_raref:
#     """
#     Explore alpha diversity as a function of sampling depth

#     Computes one or more alpha diversity metrics at multiple sampling depths.
#         * In steps between 1 (optionally controlled with --p-min-depth)
#         * The value provided as --p-max-depth
#     """
#     input:
#     output:
#     shell:
#         """

#         """


rule diversity_analysis_all:
    input:
        rules.calc_core_metrics_phylo.output,
        expand(
            os.path.join(
                "output",
                "core-metrics-results",
                "{alpha_div_metric}-group-significance.qzv",
            ),
            alpha_div_metric=["faith_pd", "evenness"],
        ),
        expand(
            os.path.join(
                "output",
                "core-metrics-results",
                "unweighted-unifrac-{metadata_col}-significance.qzv",
            ),
            metadata_col=["body-site", "subject"],
        ),
        expand(
            os.path.join(
                "output",
                "core-metrics-results",
                "{beta_div_metric}-emperor-days-since-experiment-start.qzv",
            ),
            beta_div_metric=["unweighted_unifrac", "bray_curtis"],
        ),
