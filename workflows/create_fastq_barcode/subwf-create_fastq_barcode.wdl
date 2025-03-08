version 1.0

workflow wf_create_fastq_barcode {
  input {
    Array[File] fastq_files
    File? onlist
  }

  scatter (i in range(length(fastq_files))) {
    call create_fastq_barcode {
      input:
        fastq_file = fastq_files[i]
    }
  }

  if (defined(onlist)) {
    call split_onlist {
      input:
        onlist = select_first([onlist])
    }
  }

  output {
    Array[File] fastq_barcodes = create_fastq_barcode.fastq_barcodes
    Array[File] fastq_R2_no_barcodes = create_fastq_barcode.fastq_R2_no_barcodes
    File? onlist_R1 = split_onlist.onlist_R1
    File? onlist_R2 = split_onlist.onlist_R2
    File? onlist_R3 = split_onlist.onlist_R3
    File? onlist_multi_kb = split_onlist.onlist_multi_kb
  }
}

# The task takes in input a FASTQ file where the last 99 bases are the raw barcode sequence and the rest of the sequence is the read sequence and split them.
task create_fastq_barcode {
  input {
    File fastq_file
  }

  Float input_file_size_gb = size(fastq_file, "G")
  Int disk_gb = round(20.0 + 3 * input_file_size_gb)
  String disk_type = if disk_gb > 375 then "SSD" else "LOCAL"


  String prefix = basename(fastq_file, ".fastq.gz")

  command <<<
    gzip -dc ~{fastq_file} | awk '{if(NR%4==2) print substr($0,1,length($0)-99)}' | gzip -c > ~{prefix}.barcodes.fastq.gz
    gzip -dc ~{fastq_file} | awk '{if(NR%4==2) print substr($0,length($0)-99)}'   | gzip -c > ~{prefix}.R2_no_barcode.fastq.gz
  >>>

  output {
    File fastq_barcodes = "~{prefix}.barcodes.fastq.gz"
    File fastq_R2_no_barcodes = "~{prefix}.R2_no_barcode.fastq.gz"
  }

  runtime {
    docker: "ubuntu:latest"
    disks : "local-disk ${disk_gb} ${disk_type}"
  }
}

# The task takes in input an onlist file where each row is a 24 bp barcode seqeunce and split it into three files.
# The first file contains the first 8 bp of the barcode, the second file contains the second 8 bp of the barcode, and the third file contains the last 8 bp of the barcode.
# last step is also producing an onlist for the RNA which is the column concatenation os the three files.
task split_onlist {
  input {
    File onlist
  }

  String prefix = basename(onlist, "_whitelist.txt")

  Int disk_gb = 50
  String disk_type = if disk_gb > 375 then "SSD" else "LOCAL"

  command <<<
    awk '{print substr($0,1,8)}' ~{onlist} | uniq | sort -u > ~{prefix}_onlist_round1_subset.txt
    awk '{print substr($0,9,8)}' ~{onlist} | uniq | sort -u > ~{prefix}_onlist_round2.txt
    awk '{print substr($0,17,8)}' ~{onlist} | uniq | sort -u > ~{prefix}_onlist_round3.txt
    paste ~{prefix}_onlist_round1_subset.txt ~{prefix}_onlist_round2.txt ~{prefix}_onlist_round3.txt > ~{prefix}_onlist_multi_kb.txt
  >>>

  output {
    File onlist_R1 = "onlist_round1_subset.txt"
    File onlist_R2 = "onlist_round2.txt"
    File onlist_R3 = "onlist_round3.txt"
    File onlist_multi_kb = "onlist_multi_kb.txt"
  }

  runtime {
    docker: "ubuntu:latest"
    disks : "local-disk ${disk_gb} ${disk_type}"
    preemptible: 3
  }
}