version 1.0

# TASK
# bwtool

task bwtool_matrix {
    meta {
        version: 'v0.1'
        author: 'Eugenio Mattei (emattei@broadinstitute.org) at Broad Institute of MIT and Harvard'
        description: 'Broad Institute of MIT and Harvard: Deeptools computeMatrix'
    }

    input {
        # This task takes in input the bigwigs for input and produce the count matrix.
        Int cpus = 16
        Int memory_gb = 64
        Boolean? starts
        Boolean? ends
        String ranges
        Int? cluster_k
        Int? tiled_averages
        Boolean? long_form
        Boolean? keep_bed
        Array[String]? long_form_labels
        Boolean? long_form_header
        Array[File] bigwigs
        Array[File] regions_bed
        String docker_image = "polumechanos/bwtools"
        String prefix = "bwtool"
        String extra_annotation = ""

    }

    #Float input_file_size_gb = size(fastq_R1, "G")
    # This is almost fixed for either mouse or human genome
    Int mem_gb = memory_gb
    #Int disk_gb = round(20.0 + 4 * input_file_size_gb)
    Int disk_gb = 100
    String region_basenames = basename(regions_bed[0], ".bed")
    String cluster_file = "${prefix}_${extra_annotation}_${region_basenames}_matrix_cluster_annotated_k_${cluster_k}.bed"
    String output_matrix = "${prefix}_${extra_annotation}_${region_basenames}_matrix.txt"


    command {

        /software/bwtool matrix \
            ${true='-starts ' false=' ' starts} \
            ${true='-ends ' false=' ' ends} \
            ${ranges} \
            ${sep="," regions_bed} \
            ${sep="," bigwigs} \
            ${output_matrix} \
            ${true='-long-form=' false=' ' long_form}${sep="," long_form_labels } \
            ${true='-long-form-header ' false=' ' long_form_header} \
            ${true='-keep-bed ' false=' ' keep_bed} \
            ${'-tiled-averages=' + tiled_averages} \
            ${"-cluster " + cluster_k}
    }

    output {
        File bwtool_matrix_output = "${output_matrix}"
        File? bwtool_matrix_cluster_output = "${cluster_file}"
    }

    runtime {
        cpu : cpus
        memory : mem_gb+'G'
        disks : 'local-disk ${disk_gb} SSD'
        docker : docker_image
        monitoring_script: "gs://fc-a30e1a42-4d9b-4dc9-b343-aab547e1ee09/cromwell_monitoring_script2.sh"
    }

}
