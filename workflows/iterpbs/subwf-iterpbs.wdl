version 1.0

import "../../tasks/task_iterpbs.wdl" as task_iterpbs

workflow wf_iterpbs{
    meta {
        version: 'v0.1'
            author: 'Siddarth Wekhande (swekhand@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Run PBS iteratively on compartments'
    }
    
    input {
        File binned_bed
        File A_compartments_bed
        File B_compartments_bed
        String? prefix = "prefix"
    }
    
    call task_iterpbs.iter_pbs as pbs {
        input:
            binned_bed = binned_bed,
            A_compartments_bed = A_compartments_bed,
            B_compartments_bed = B_compartments_bed,
            prefix = prefix
    }
    
    output {
        File pbs_corrected_bed = pbs.pbs_corrected_bed
        File pbs_corrected_plot = pbs.pbs_corrected_plot
        File pbs_original_plot = pbs.pbs_original_plot
        File pbs_compartment_fit_plot = pbs.pbs_compartment_fit_plot
        File pbs_joint_plot = pbs.pbs_joint_plot
    }
}