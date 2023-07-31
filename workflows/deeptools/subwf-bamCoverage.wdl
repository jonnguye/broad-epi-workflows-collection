version 1.0

import "../../tasks/task_deeptools_coverage.wdl" as task_deeptools

workflow wf_deeptools{
    meta {
        version: 'v0.1'
            author: 'Eugenio Mattei (emattei@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Deeptools.'
    }

    call task_deeptools.bamCoverage as coverage

    output {
        File deeptools_bw = coverage.cleaned_deeptools_bw
    }
}

