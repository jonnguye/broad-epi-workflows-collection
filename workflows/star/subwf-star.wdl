version 1.0

import "../../tasks/task_star.wdl" as task_star

workflow wf_deeptools{
    meta {
        version: 'v0.1'
            author: 'Siddarth Wekhande (swekhand@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: STAR.'
    }
    
    input {
        # RNA Sub-worflow inputs

        # Align
        Array[File] read1
        Array[File]? read2
        File idx_tar
        String prefix = "rna-project"
        String genome_name
        Int? cpus = 16
        String? docker
    }

    call task_star.rna_align as align {
        input:
            fastq_R1 = read1,
            fastq_R2 = read2,
            genome_name = genome_name,
            genome_index_tar = idx_tar,
            prefix = prefix,
            cpus = cpus
    }
    
    output {
        File rna_alignment_raw = align.rna_alignment
        File rna_alignment_index = align.rna_alignment_index
        File rna_alignment_log = align.rna_alignment_log
    }
}

