
rule generate_phylogeny_tree:
    """
    1. Use mafft program to perform a multiple sequence alignment of the sequences in our FeatureData[Sequence] to create a FeatureData[AlignedSequence] QIIME 2 artifact.
        * https://gitlab.com/sysimm/mafft
    2. Mask (or filters) the alignment to remove positions that are highly variable.
        * These positions are generally considered to add noise to a resulting phylogenetic tree.
    3. Apply FastTree to generate a phylogenetic tree from the masked alignment.
        * The FastTree program creates an unrooted tree.
        * http://www.microbesonline.org/fasttree/
    4. Midpoint rooting is applied to place the root of the tree at the midpoint of the longest tip-to-tip distance in the unrooted tree.
    """
    input:
        rules.denoise_deblur_seqs.output.rep_seqs_deblur,
    output:
        # 1
        aligned_seq=os.path.join("data", "tree", "aligned-rep-seqs.qza"),
        # 2
        masked_aligned_seq=os.path.join("data", "tree", "masked-aligned-rep-seqs.qza"),
        # 3
        unrooted_tree=os.path.join("data", "tree", "unrooted-tree.qza"),
        # 4
        rooted_tree=os.path.join("data", "tree", "rooted-tree.qza"),
    log:
        "logs/generate_phylogeny_tree",
    shell:
        """
        qiime phylogeny align-to-tree-mafft-fasttree \
        --i-sequences {input} \
        --o-alignment {output.aligned_seq} \
        --o-masked-alignment {output.masked_aligned_seq} \
        --o-tree {output.unrooted_tree} \
        --o-rooted-tree {output.rooted_tree} &> {log}
        """
