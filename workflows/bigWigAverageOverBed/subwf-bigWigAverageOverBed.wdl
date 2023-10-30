version 1.0

import "../../tasks/task_bigWigAverageOverBed.wdl" as task_bigWigAverageOverBed

workflow wf_bigWigAverageOverBed{
    meta {
        version: 'v0.1'
            author: 'Eugenio Mattei (emattei@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Deeptools.'
    }

    call task_bigWigAverageOverBed.bigWigAverageOverBed as average

    output {
        File bigWigAveragedOverBed = average.bigWigAveragedOverBed
    }
}