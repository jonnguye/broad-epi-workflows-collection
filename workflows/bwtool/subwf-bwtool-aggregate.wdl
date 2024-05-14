version 1.0

import "../../tasks/task_bwtool_aggregate.wdl" as bwtool_aggregate

workflow bwtool_aggregate_wf {
    meta {
        version: 'v0.1'
            author: 'Eugenio Mattei (emattei@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Deeptools.'
    }

    input {
        Array[File] bwtool_aggregate_regions
        Array[String] ranges
    }

    scatter (idx in range(length(bwtool_aggregate_regions))) {
        call bwtool_aggregate.bwtool_aggregate as bwtool_aggregate {
            input: 
                regions_bed = [bwtool_aggregate_regions[idx]],
                ranges = ranges[idx]
        }
    }

    output {
        Array[File] bwtool_aggregate_output = bwtool_aggregate.bwtool_aggregate_output
        Array[File?] bwtool_cluster_output = bwtool_aggregate.bwtool_cluster_output
        }
}

