version 1.0

# TASK
# deeptools

task deeptools_computeMatrix {
    meta {
        version: 'v0.1'
        author: 'Eugenio Mattei (emattei@broadinstitute.org) at Broad Institute of MIT and Harvard'
        description: 'Broad Institute of MIT and Harvard: Deeptools computeMatrix'
    }

    input {
        # This task takes in input the bigwigs for input and produce the count matrix.
        Int cpus = 16
        Int memory_gb = 64
        Int bin_size = 50
        Array[File] bigwigs
        Array[File] regions_bed
        String docker_image = "njaved/deeptools"
        String? prefix

        String mode = "reference-point" # reference-point or scale-regions
        Int beforeRegionStartLength = 3000
        Int afterRegionStartLength = 3000
        Int? regionBodyLength
        Boolean skipZeros = true
        String sortRegions = "keep"

    }

    #Float input_file_size_gb = size(fastq_R1, "G")
    # This is almost fixed for either mouse or human genome
    Int mem_gb = memory_gb
    #Int disk_gb = round(20.0 + 4 * input_file_size_gb)
    Int disk_gb = 100


    command {

        computeMatrix ${mode} -S ${sep=" " bigwigs} \
            -R ${sep=" " regions_bed} \
            --beforeRegionStartLength ${beforeRegionStartLength} \
            --afterRegionStartLength ${afterRegionStartLength} \
            -p 16 \
            ${true='--skipZeros ' false='' skipZeros} \
            ${"--regionBodyLength " + regionBodyLength} \
            ${"--sortRegions " + sortRegions} \
            ${"-bs " + bin_size} \
            -o ${prefix}.mat.gz

        plotHeatmap -m ${prefix}.mat.gz -o ${prefix}.heatmap.pdf
    }

    output {
        File deeptools_computed_matrix = "$${prefix}.mat.gz"
        File deeptools_heatmap = "${prefix}.heatmap.tss.pdf"
    }

    runtime {
        cpu : cpus
        memory : mem_gb+'G'
        disks : 'local-disk ${disk_gb} SSD'
        docker : docker_image
    }

}
