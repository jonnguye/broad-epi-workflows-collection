version 1.0

import "../../tasks/task_bedGraphToBigWig.wdl" as task_bedGraphToBigWig

workflow wf_bedGraphToBigWig{
    meta {
        version: 'v0.1'
            author: 'Eugenio Mattei (emattei@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Deeptools.'
    }

    call task_bedGraphToBigWig.bedGraphToBigWig as convert

    output {
        File converted_bw = convert.converted_bw
    }
}