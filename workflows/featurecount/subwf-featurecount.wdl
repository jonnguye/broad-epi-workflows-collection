version 1.0

import "../../tasks/task_featurecount.wdl" as task_featurecount

workflow wf_featurecount{
    meta {
        version: 'v0.1'
            author: 'Siddarth Wekhande (swekhand@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Feature counts.'
    }

    input {
        File input_bam
        String prefix = "output-prefix"
        String genome_name
        String? docker
        File gtf
        Boolean include_multimappers = false
        Boolean include_introns = false
        String gene_naming = "gene_name"
    }

    call task_featurecount.feature_counts_rna as count{
        input:
            multimapper = include_multimappers,
            intron = include_introns,
            bam = input_bam,
            gtf = gtf,
            gene_naming = gene_naming,
            genome_name = genome_name,
            prefix = prefix
    }

    output {
        File rna_featurecount_alignment = count.rna_featurecount_alignment
        File rna_featurecount_alignment_index = count.rna_featurecount_alignment_index
        File rna_featurecount_exon_txt = count.rna_featurecount_exon_txt
        File? rna_featurecount_intron_txt = count.rna_featurecount_intron_txt

    }
}

