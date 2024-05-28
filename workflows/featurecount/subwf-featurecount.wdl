version 1.0

import "../../tasks/task_featurecount.wdl" as task_featurecount

workflow wf_featurecount{
    meta {
        version: 'v0.1'
            author: 'Siddarth Wekhande (swekhand@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Feature counts.'
    }

    call task_featurecount.feature_counts_rna as count

    output {
        File rna_featurecount_count = count.rna_featurecount_counts
        File rna_featurecount_summary = count.rna_featurecount_summary
    }
}

