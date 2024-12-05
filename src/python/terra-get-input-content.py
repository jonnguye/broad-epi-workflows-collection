#Get input metadata from Terra workflow. This script is specifically used to retrieve the fastq gs links in the DACC Anvil/IGVF Single-Cell Data Processing workspace

from firecloud import api as fapi
import pandas as pd 
import json
import os

def extract_ids(data):
    try:
        parts = data.split('/')
        return parts[4], parts[6]  # Adjusting for zero-based indexing
    except:
        return None, None  # Handle cases where there aren't enough parts

file_path = "Team_1.tsv"
df = pd.read_csv(file_path, sep='\t')

df["ATAC_barcode_fastq_gs_path"] = ""
df["ATAC_r1_gs_path"] = ""
df["ATAC_r2_gs_path"] = ""
df["RNA_r1_gs_path"] = ""
df["RNA_r2_gs_path"] = ""

# Iterate over the DataFrame rows
for index, row in df.iterrows():
    # Process ATAC_barcode column
    atac_data = row.get("atac_filter_fragments", "None")
    atac_4th, atac_6th = extract_ids(atac_data)
    
    # Process rna_log column
    rna_data = row.get("rna_kb_output", "")
    rna_4th, rna_6th = extract_ids(rna_data)
    
    print(index)
    #print(atac_4th)
    
    if(atac_4th != None):
        response = fapi.get_workflow_metadata("DACC_ANVIL", "IGVF Single-Cell Data Processing", atac_4th, atac_6th)

        df.loc[index, "ATAC_barcode_fastq_gs_path"] = json.dumps(response.json()['calls']["multiome_pipeline.atac"][0]["inputs"]["fastq_barcode"])

        df.loc[index, "ATAC_r1_gs_path"] = json.dumps(response.json()['calls']["multiome_pipeline.atac"][0]["inputs"]["read1"])

        df.loc[index, "ATAC_r2_gs_path"] = json.dumps(response.json()['calls']["multiome_pipeline.atac"][0]["inputs"]["read2"])
    
    if(rna_4th != None):
        response = fapi.get_workflow_metadata("DACC_ANVIL", "IGVF Single-Cell Data Processing", rna_4th, rna_6th)
        
        df.loc[index, "RNA_r1_gs_path"] = json.dumps(response.json()['calls']["multiome_pipeline.rna"][0]["inputs"]["read1"])

        df.loc[index, "RNA_r2_gs_path"] = json.dumps(response.json()['calls']["multiome_pipeline.rna"][0]["inputs"]["read2"])
    
df.to_csv(os.path.basename(file_path).split(".")[0] + "_modified.tsv", sep = "\t", index = False)



