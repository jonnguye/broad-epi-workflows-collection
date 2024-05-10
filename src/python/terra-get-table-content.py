#!/usr/bin/env python3

# Create a Manifest file to uplaod the results of the data processing jamboree to Synapse
# Originally created by Diane Trout
# Modified by Eugenio Mattei

import numpy
import pandas
import sys
from anvil.terra.api import FAPI
from anvil.terra.api import get_projects, get_entities
from anvil.terra import api
from google.cloud import storage
from pathlib import Path

client = storage.Client()

# Parameters need to contact the workspace
# workspace = os.environ['WORKSPACE_NAME']
# namespace = os.environ['WORKSPACE_NAMESPACE']
# project = os.environ["GOOGLE_PROJECT"]
# bucket_root = os.environ["WORKSPACE_BUCKET"]

namespace = "DACC_ANVIL"
workspace = "IGVF Single-Cell Data Processing Jamboree"
project = "anvil-datastorage"
bucket_root = "fc-secure-0a879173-62d3-4c3a-8fc3-e35ee4248901"
local_bucket_root = "jamboree-gs"

bucket = client.get_bucket(bucket_root)

parent_ids={
    "Team_1": "syn52118178",
    "Team_2": "syn52117507",
    "Team_3": "syn52118179",
    "Team_4": "syn52118180",
    "Team_5": "syn52118181",
    "Team_6": "syn52118183",
    "Team_6Jesse": "syn52118183",
    "Team_7": "syn52118184",
    "Team_8": "syn52118187"
}


# Init
table_name = "Team_6"
synapse_parent_id = parent_ids[table_name]
columns_to_save = {
    "share_rna_starsolo_raw_tar": "https://github.com/broadinstitute/epi-SHARE-seq-pipeline/blob/IGVF-variant-jamboree/tasks/share_task_starsolo.wdl", 
    "share_rna_final_bam": "https://github.com/broadinstitute/epi-SHARE-seq-pipeline/blob/IGVF-variant-jamboree/tasks/share_task_starsolo.wdl",
    "share_rna_barcode_metadata": "https://github.com/broadinstitute/epi-SHARE-seq-pipeline/blob/IGVF-variant-jamboree/tasks/share_task_qc_rna.wdl",
    "joint_barcode_metadata": "https://github.com/broadinstitute/epi-SHARE-seq-pipeline/blob/IGVF-variant-jamboree/tasks/share_task_joint_qc.wdl", 
    "html_summary": "https://github.com/broadinstitute/epi-SHARE-seq-pipeline/blob/IGVF-variant-jamboree/tasks/task_html_report.wdl", 
    "share_atac_filter_fragments": "https://github.com/broadinstitute/epi-SHARE-seq-pipeline/blob/IGVF-variant-jamboree/tasks/task_chromap.wdl", 
    "share_atac_filter_fragments_index": "https://github.com/broadinstitute/epi-SHARE-seq-pipeline/blob/IGVF-variant-jamboree/tasks/task_chromap.wdl", 
    "share_atac_barcode_metadata": "https://github.com/broadinstitute/epi-SHARE-seq-pipeline/blob/IGVF-variant-jamboree/tasks/task_qc_atac.wdl", 
    "share_rna_h5": "https://github.com/broadinstitute/epi-SHARE-seq-pipeline/blob/IGVF-variant-jamboree/tasks/share_task_generate_h5.wdl"
}

provenance_dict = {
    "share_rna_starsolo_raw_tar": [""], 
    "share_rna_final_bam": [""],
    "share_rna_barcode_metadata": ["share_rna_starsolo_raw_tar"],
    "joint_barcode_metadata": ["share_atac_barcode_metadata","share_rna_barcode_metadata"], 
    "html_summary": ["joint_barcode_metadata"], 
    "share_atac_filter_fragments": [""], 
    "share_atac_filter_fragments_index": [""], 
    "share_atac_barcode_metadata": ["share_atac_filter_fragments"], 
    "share_rna_h5": ["share_rna_starsolo_raw_tar"]
}

# Get the table content
table = FAPI.get_entities(namespace, workspace, table_name).json()

index = []
records = []
for row in table:
    #print(row["name"], row["entityType"])
    attributes = row["attributes"]
    for key in attributes:
        value = attributes[key]
        if isinstance(value, dict):
            if value["itemsType"] == "AttributeValue":
                attributes[key] = value["items"]
            else:
                print("Unrecognized itemsType {}".format(value["itemsType"]))
    
    index.append(row["name"])
    records.append(attributes)
    
df = pandas.DataFrame(records)
df.index = index

print("path\tparent\tname\tsubpool\tmd5_google\texecuted\tused")
manifest = []
files_to_transfer = {}
for subpool, row in df.iterrows():
    for column, git in columns_to_save.items():
        attribute = row.get(column)
        if pandas.isnull(attribute):
            pass
        elif isinstance(attribute, list):
            for value in attribute:
                path = Path(value)
                name = path.name
                # This should be extracted in a function because I am using the same
                # code multiple times.
                blob = bucket.blob(str(path.relative_to(*path.parts[:2])))
                local_path = f"{local_bucket_root}/{str(path.relative_to(*path.parts[:2]))}"
                blob.reload()
                md5 = blob.md5_hash
                provenance=[]
                for task in provenance_dict[column]:
                    if task and df.loc[subpool][task]  and not isinstance(df.loc[subpool][task], numpy.float64):
                        provenance.append(df.loc[subpool][task])
                manifest.append(f"{local_path}\t{synapse_parent_id}\t{name}\t{subpool}\t{md5}\t{git}\t{';'.join(provenance)}")
                files_to_transfer[name] = value
                
        else:
            path = Path(attribute)
            name = path.name
            # Removing the name of the bucket
            blob = bucket.blob(str(path.relative_to(*path.parts[:2])))
            # Apparently the reload is necessary
            # https://cloud.google.com/python/docs/reference/storage/1.37.1/blobs
            blob.reload()
            md5 = str(blob.md5_hash)
            local_path = f"{local_bucket_root}/{str(path.relative_to(*path.parts[:2]))}"
            provenance=[]
            for task in provenance_dict[column]:
                    if task and df.loc[subpool][task]  and not isinstance(df.loc[subpool][task], numpy.float64):
                        provenance.append(df.loc[subpool][task])
            manifest.append(f"{local_path}\t{synapse_parent_id}\t{name}\t{subpool}\t{md5}\t{git}\t{';'.join(provenance)}")
            files_to_transfer[name] = attribute

print(len(manifest),file=sys.stderr)

print("\n".join(manifest))
#print(files_to_transfer)