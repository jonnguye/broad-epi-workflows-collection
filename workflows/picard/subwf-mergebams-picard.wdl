version 1.0

import "../../tasks/task_mergebams_picard.wdl" as task_mergebams_picard

workflow wf_mergebams_picard{
    meta {
        version: 'v0.1'
            author: 'Siddarth Wekhande (swekhand@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Merge BAMs using Picard.'
    }
    
    input {
        Array[File] bam_inputs
        String? prefix
        String? sort_order = "coordinate"
        cpu = 8
        disk = 500
    }
    
    call task_mergebams_picard.MergeSortBamFiles as merge{
        input:
            bam_inputs = bam_inputs,
            prefix = prefix,
            sort_order = sort_order,
            cpu = cpu,
            disk = disk
    }
    
    output {
        File merged_bam = merge.output_bam
    }
}