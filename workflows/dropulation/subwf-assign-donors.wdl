version 1.0

import "../../tasks/task_assign_donors.wdl" as task_assign_donors

workflow wf_assign_donors{
    meta {
        version: 'v0.1'
            author: 'Siddarth Wekhande (swekhand@broadinstitute.org) @ Broad Institute of MIT and Harvard'
            description: 'Broad Institute of MIT and Harvard: Assign donors using Dropulation.'
    }

    input {
        File rna_bam
        File atac_bam
        File input_vcf
        File input_vcf_index
        File barcode_list
        File? annotations_gtf
        String? prefix
    }
    
    Boolean process_atac = if atac_bam != "" then true else false
    Boolean process_rna = if rna_bam != "" then true else false
    
    if ( process_rna ) {

        call task_assign_donors.assign_donors as rna_assign{
            input:
                input_bam = rna_bam,
                input_vcf = input_vcf,
                input_vcf_index = input_vcf_index,
                barcode_list = barcode_list,
                annotations_gtf = annotations_gtf,
                modality = "rna",
                prefix = prefix
        }
    
    }
    
    if ( process_atac ) {

        call task_assign_donors.assign_donors as atac_assign{
            input:
                input_bam = atac_bam,
                input_vcf = input_vcf,
                input_vcf_index = input_vcf_index,
                barcode_list = barcode_list,
                modality = "atac",
                prefix = prefix
        }
    
    }

    output {
        File? rna_donor_assignments = rna_assign.donor_assignments
        File? rna_donor_assignments_vcf = rna_assign.donor_assignments_vcf
        File? atac_donor_assignments = atac_assign.donor_assignments
        File? atac_donor_assignments_vcf = atac_assign.donor_assignments_vcf
    }
}

