version 1.0

import "../../tasks/task_igvtools_count.wdl" as task_igvtools

workflow wf_igvtools{
    meta {
        version: 'v0.1'
            author: 'Eugenio Mattei (emattei@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Deeptools.'
    }

    call task_igvtools.igvtools_count as count

    output {
        File igvtools_count_bw = count.igvtools_count_bw
    }
}