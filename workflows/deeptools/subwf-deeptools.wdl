version 1.0

import "../../tasks/task_deeptools.wdl" as task_deeptools

workflow wf_deeptools{
    meta {
        version: 'v0.1'
            author: 'Eugenio Mattei (emattei@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Deeptools.'
    }

    input {
        File input_bam
        File chrom_sizes
        File tss
        File genes
        String prefix = "output-prefix"
        String genome_name
        String? docker
    }

    call task_deeptools.deeptools as deeptools {
        input:
            cleaned_bam = input_bam,
            chr_sizes = chrom_sizes,
            tss = tss,
            genes = genes,
            prefix = prefix
    }


    output {
        File deeptools_heatmap_genes = deeptools.heatmap_genes
        File deeptools_heatmap_tss = deeptools.heatmap_tss
        File deeptools_bw = deeptools.cleaned_deeptools_bw

    }
}

