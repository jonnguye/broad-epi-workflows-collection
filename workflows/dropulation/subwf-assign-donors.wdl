version 1.0

import "../../tasks/task_assign_donors.wdl" as task_assign_donors

workflow wf_assign_donors{
    meta {
        version: 'v0.1'
            author: 'Siddarth Wekhande (swekhand@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Assign donors using Dropulation.'
    }

    input {
        File input_bam
        File input_vcf
        File input_vcf_index
        File barcode_list
        File? annotations_gtf
        String modality
        String? prefix
    }

    call task_assign_donors.assign_donors as assign{
        input:
            input_bam = input_bam,
            input_vcf = input_vcf,
            input_vcf_index = input_vcf_index,
            barcode_list = barcode_list,
            annotations_gtf = annotations_gtf,
            modality = modality,
            prefix = prefix
    }

    output {
        File donor_assignments = assign.donor_assignments
        File donor_assignments_vcf = assign.donor_assignments_vcf
    }
}

