version 1.0

# TASK
# bwtool

task bwtool_aggregate {
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
        Boolean? expanded
        Boolean? firstbase
        Int? cluster_k
        Boolean? long_form
        Array[String]? long_form_labels
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
    String cluster_file = "${prefix}_${extra_annotation}_${region_basenames}_cluster_annotated_k_${cluster_k}.bed"
    String output_aggregate = "${prefix}_${extra_annotation}_${region_basenames}_aggregate.txt"


    command {

        /software/bwtool aggregate \
            ${true='-starts ' false=' ' starts} \
            ${true='-ends ' false=' ' ends} \
            ${ranges} \
            ${sep="," regions_bed} \
            ${sep="," bigwigs} \
            ${output_aggregate} \
            ${true='-expanded ' false=' ' expanded} \
            ${true='-firstbase ' false=' ' firstbase} \
            ${true='-long-form=Regions,' false=' ' long_form}${sep="," long_form_labels } \
            ${"-cluster=" + cluster_k}
    }

    output {
        File bwtool_aggregate_output = "${output_aggregate}"
        File? bwtool_cluster_output = "${cluster_file}"
    }

    runtime {
        cpu : cpus
        memory : mem_gb+'G'
        disks : 'local-disk ${disk_gb} SSD'
        docker : docker_image
    }

}
