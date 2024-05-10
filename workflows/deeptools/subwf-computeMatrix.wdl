version 1.0

import "../../tasks/task_deeptools_computematrix.wdl" as compute_matrix

workflow deeptools_compute_matrix{
    meta {
        version: 'v0.1'
            author: 'Eugenio Mattei (emattei@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Deeptools.'
    }

    call compute_matrix.deeptools_computeMatrix as computeMatrix

    output {
        File deeptools_computed_matrix = computeMatrix.deeptools_computed_matrix
        }
}

