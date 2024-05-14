version 1.0

import "../../tasks/task_bwtool_matrix.wdl" as bwtool_matrix

workflow bwtool_matrix_wf {
    meta {
        version: 'v0.1'
            author: 'Eugenio Mattei (emattei@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Deeptools.'
    }
    input {
        Array[File] bwtool_matrix_regions
        Array[String] ranges
    }
    
    scatter (idx in range(length(bwtool_matrix_regions))) {
        call bwtool_matrix.bwtool_matrix as bwtool_matrix{
            input:
                regions_bed = [bwtool_matrix_regions[idx]],
                ranges = ranges[idx]
        }
    }

    output {
        Array[File] bwtool_matrix_output = bwtool_matrix.bwtool_matrix_output
        Array[File?] bwtool_matrix_cluster_output = bwtool_matrix.bwtool_matrix_cluster_output
        }
}

