version 1.0

# TASK
# Assign donors using Dropulation

task assign_donors {
    meta {
        version: 'v0.1'
        author: 'Siddarth Wekhande (swekhand@broadinstitute.org) at Broad Institute of MIT and Harvard'
        description: 'Broad Institute of MIT and Harvard RNA align: genetic demultiplexing'
    }

    input {
        # This function takes in input the VCF, BAM and barcode list to assign barcode to donors specified in VCF. 

        File input_bam
        File input_vcf
        File input_vcf_index
        File barcode_list
        File? annotations_gtf
        String modality
        String? prefix
        String docker_image = "us.gcr.io/landerlab-atacseq-200218/landerlab-dropseq-2.5.0:1.0"
        Int cpus = 16
        Int disk_gb = 100
        Int mem_gb = 128
    }

    # Define the output names
    String assignments = "${prefix}.${modality}.donor_assignments.txt.gz"
    String assignments_vcf = "${prefix}.${modality}.donor_assignments.vcf.gz"

    command {
        set -e
        /software/monitor_script.sh &
        
        if [[ "${modality}" == "rna" ]]
        then
            java -Xmx128g -jar /software/Drop-seq_tools/jar/dropseq.jar TagReadWithGeneFunction \
            --ANNOTATIONS_FILE ${annotations_gtf} \
            -I ${input_bam} \
            -O tagread.bam
            
            rm ${input_bam}
            
            java -Xmx128g -jar /software/Drop-seq_tools/jar/dropseq.jar AssignCellsToSamples \
            --INPUT_BAM tagread.bam \
            --VCF ${input_vcf} \
            --OUTPUT ${assignments} \
            --VCF_OUTPUT ${assignments_vcf} \
            --CELL_BARCODE_TAG CB \
            --CELL_BC_FILE ${barcode_list} \
            --FRACTION_SAMPLES_PASSING 0.3 \
            --DNA_MODE false \
            --TMP_DIR /tmp \
            --MOLECULAR_BARCODE_TAG UB \
            --FUNCTION_TAG XF \
            --EDIT_DISTANCE 1 \
            --READ_MQ 10 \
            --RETAIN_MONOMORPIC_SNPS false \
            --IGNORED_CHROMOSOMES X \
            --IGNORED_CHROMOSOMES Y \
            --IGNORED_CHROMOSOMES MT \
            --ADD_MISSING_VALUES true \
            --SNP_LOG_RATE 1000 \
            --GENE_NAME_TAG gn \
            --GENE_STRAND_TAG gs \
            --GENE_FUNCTION_TAG gf \
            --STRAND_STRATEGY SENSE \
            --LOCUS_FUNCTION_LIST CODING \
            --LOCUS_FUNCTION_LIST UTR \
            --LOCUS_FUNCTION_LIST INTERGENIC \
            --LOCUS_FUNCTION_LIST INTRONIC \
            --VERBOSITY INFO \
            --QUIET false \
            --VALIDATION_STRINGENCY STRICT \
            --COMPRESSION_LEVEL 5 \
            --MAX_RECORDS_IN_RAM 500000 \
            --CREATE_INDEX false \
            --CREATE_MD5_FILE false \
            --help false \
            --version false \
            --showHidden false 
        else
            mv ${input_bam} tagread.bam
            
            java -Xmx128g -jar /software/Drop-seq_tools/jar/dropseq.jar AssignCellsToSamples \
            --INPUT_BAM tagread.bam \
            --VCF ${input_vcf} \
            --OUTPUT ${assignments} \
            --VCF_OUTPUT ${assignments_vcf} \
            --CELL_BARCODE_TAG CB \
            --CELL_BC_FILE ${barcode_list} \
            --FRACTION_SAMPLES_PASSING 0.3 \
            --DNA_MODE true \
            --TMP_DIR /tmp \
            --MOLECULAR_BARCODE_TAG XM \
            --FUNCTION_TAG XF \
            --EDIT_DISTANCE 1 \
            --READ_MQ 10 \
            --RETAIN_MONOMORPIC_SNPS false \
            --IGNORED_CHROMOSOMES X \
            --IGNORED_CHROMOSOMES Y \
            --IGNORED_CHROMOSOMES MT \
            --ADD_MISSING_VALUES true \
            --SNP_LOG_RATE 1000 \
            --GENE_NAME_TAG gn \
            --GENE_STRAND_TAG gs \
            --GENE_FUNCTION_TAG gf \
            --STRAND_STRATEGY SENSE \
            --LOCUS_FUNCTION_LIST CODING \
            --LOCUS_FUNCTION_LIST UTR \
            --VERBOSITY INFO \
            --QUIET false \
            --VALIDATION_STRINGENCY STRICT \
            --COMPRESSION_LEVEL 5 \
            --MAX_RECORDS_IN_RAM 500000 \
            --CREATE_INDEX false \
            --CREATE_MD5_FILE false \
            --help false \
            --version false \
            --showHidden false
       fi 
    }

    output {
        File donor_assignments = "${assignments}"
        File donor_assignments_vcf = "${assignments_vcf}"
    }

    runtime {
        cpu : cpus
        memory : mem_gb+'G'
        disks : 'local-disk ${disk_gb} SSD'
        maxRetries: 0
        docker: docker_image
    }

    parameter_meta {
        input_bam: {
                description: 'Aligned sequences with CB tag',
                help: 'BAM files with barcodes in CB tag.',
                example: 'aligned.bam'
            }
        input_vcf: {
                description: 'Genotyping information of each donor',
                help: 'VCF containing SNP info of each donor to which barcodes will be assigned.',
                example: ['donors.vcf.gz']
            }
        input_vcf_index: {
                description: 'Tabix index of VCF',
                help: 'VCF file must be indexed using tabix.',
                example: ['donors.tbi']
            }
        prefix: {
                description: 'Prefix for output files',
                help: 'Prefix that will be used to name the output files',
                example: 'MyExperiment'
            }
        barcode_list: {
                description: 'List of barcodes in BAM file.',
                help: 'List of barcodes (each barcode on newline)',
                example: 'barcodes.txt.gz'
            }
        modality: {
                description: 'RNA or ATAC modality',
                help: 'Depending on modality, dropulation will run with dna_mode true or false',
                example: '[rna, atac]'
            }
        annotations_gtf: {
                description: 'Required for RNA modality. Reference genome gtf',
                help: 'Used to tag if read is intergenic, exonic, intronic',
                example: 'genes.gtf.gz'
            }
        docker_image: {
                description: 'Docker image.',
                help: 'Docker image for preprocessing step. Dependencies: STAR',
                example: ['put link to gcr or dockerhub']
            }
    }
}
