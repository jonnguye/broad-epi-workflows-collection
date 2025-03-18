version 1.0

workflow wf_create_onlist {
  input {
    String fragment_file_gs
    String prefix
  }

call create_onlist {
    input:
        fragment_file_gs = fragment_file_gs,
        prefix = prefix
}

  output {
    File onlist = create_onlist.onlist
  }
}

task create_onlist{
    input {
        String fragment_file_gs
        String prefix
    }
    command {
        gsutil cp ${fragment_file_gs} - | cut -f4 | uniq | sort -u | gzip -dc > ${prefix}_onlist_from_frag.txt.gz
    }
    output {
        File onlist = "${prefix}_onlist_from_frag.txt.gz"
    }
    runtime {
        docker: "google/cloud-sdk:stable"
        cpu: "2"
        memory: "8 GB"
    }
}