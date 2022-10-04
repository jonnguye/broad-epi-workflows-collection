version 1.0

# TASK
# deeptools

task deeptools {
    meta {
        version: 'v0.1'
        author: 'Eugenio Mattei (emattei@broadinstitute.org) at Broad Institute of MIT and Harvard'
        description: 'Broad Institute of MIT and Harvard: Deeptools QC step'
    }

    input {
        # This task takes in input the bedgraphs for input and ctrl and call peaks.
        Int? cpus = 16
        Int? memory_gb = 64
        Int? bin_size = 50
        File cleaned_bam
        File chr_sizes
        File tss
        File genes
        String? normalization = "RPGC"
        String? genome_size = "2150570000"
        String? ignore_for_normalization = "chrX"
        String docker_image = "njaved/deeptools"
        String? prefix
    }

    #Float input_file_size_gb = size(fastq_R1, "G")
    # This is almost fixed for either mouse or human genome
    Int mem_gb = memory_gb
    #Int disk_gb = round(20.0 + 4 * input_file_size_gb)
    Int disk_gb = 100


    command {
        samtools sort -@ 6 -m 6G ${cleaned_bam} -o ${prefix}.clean.sorted.bam
        samtools index ${prefix}.clean.sorted.bam

        bamCoverage --bam ${prefix}.clean.sorted.bam \
            -o ${prefix}.clean.sorted.bw \
            --binSize ${bin_size} \
            --normalizeUsing ${normalization} \
            --effectiveGenomeSize ${genome_size} \
            --ignoreForNormalization ${ignore_for_normalization}

        computeMatrix reference-point -S ${prefix}.clean.sorted.bw \
            -R ${tss} \
            --beforeRegionStartLength 3000 \
            --afterRegionStartLength 3000 \
            -p 16 \
            --skipZeros \
            -o ${prefix}.tss.mat.gz

        computeMatrix scale-regions -S ${prefix}.clean.sorted.bw \
            -R ${genes} \
            --beforeRegionStartLength 3000 \
            --afterRegionStartLength 3000 \
            --regionBodyLength 5000 \
            -p 16 \
            --skipZeros \
            -o ${prefix}.genes.mat.gz

        plotHeatmap -m ${prefix}.tss.mat.gz -o ${prefix}.heatmap.tss.pdf
        plotHeatmap -m ${prefix}.genes.mat.gz -o ${prefix}.heatmap.genes.pdf
    }

    output {
        File heatmap_genes = "${prefix}.heatmap.genes.pdf"
        File heatmap_tss = "${prefix}.heatmap.tss.pdf"
        File cleaned_deeptools_bw = glob('./*.bw')[0]
    }

    runtime {
        cpu : cpus
        memory : mem_gb+'G'
        disks : 'local-disk ${disk_gb} SSD'
        docker : docker_image
    }

}
