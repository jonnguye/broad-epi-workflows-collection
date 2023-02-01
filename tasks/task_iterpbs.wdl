version 1.0

task iter_pbs {
  input {
    File binned_bed
    File A_compartments_bed
    File B_compartments_bed
    String? prefix = "prefix"

    # runtime values
    
    String docker = "swekhande/sw-dockers:it-pbs"
    Int disk_gb = 16
    Int machine_mem_gb = 2
  }
  
  String output_pbs_corrected_bed = "${prefix}-corrected-pbs.bed"
  String output_pbs_corrected_plot = "${prefix}-fit-after-correction.png"
  String output_pbs_original_plot = "${prefix}-fit-before-correction.png"
  String output_pbs_compartment_fit_plot = "${prefix}-fit-per-compartment.png"
  String output_pbs_joint_plot = "${prefix}-joint.png"

  meta {
    description: "Run Iterative PBS given A & B cmpartment file."
  }

  parameter_meta {
    binned_bed: "PBS binned bed file"
    A_compartments_bed: "bed file of A compartments"
    B_compartments_bed: "bed file of B compartments"
    docker: "(optional) the docker image containing the runtime environment for this task"
    machine_mem_gb: "(optional) the amount of memory (GiB) to provision for this task"
    disk_gb: "(optional) the amount of disk space (GiB) to provision for this task"
  }

  command {
    set -e
    
    #reformats pbs bed file and outputs cleaned.bed
    Rscript $(which fixPBSOutput.R) -i ${binned_bed} 
    
    bedtools intersect -a ${binned_bed} -b ${A_compartments_bed} > ${prefix}.A.binned_final.bed
    bedtools intersect -a ${binned_bed} -b ${B_compartments_bed} > ${prefix}.B.binned_final.bed
    
    Rscript $(which IterPBS.R) -i cleaned.bed -a ${prefix}.A.binned_final.bed -b ${prefix}.B.binned_final.bed -p ${prefix}
    
  }

  runtime {
    docker: docker
    memory: "${machine_mem_gb} GiB"
    disks: "local-disk ${disk_gb} HDD"
    disk: disk_gb + " GB" 
  }
  output {
  
    File pbs_corrected_bed = output_pbs_corrected_bed
    File pbs_corrected_plot = output_pbs_corrected_plot
    File pbs_original_plot = output_pbs_original_plot
    File pbs_compartment_fit_plot = output_pbs_compartment_fit_plot
    File pbs_joint_plot = output_pbs_joint_plot
    
  }
}

