#!/usr/bin/env python3

"""
https://github.com/broadinstitute/horsefish/pull/142


Output = a file that contains new line delimited paths to all outputs from successful workflows in all submissions in a single workspace.

General steps of script:

    accepts a single workspace project and workspace name.
    gets list of all submission_id values in workspace*
    creates dictionary of submission_ids and successful workflow_ids --> {submission_id: [successful_workflow_ids]}
    for each item in dictionary, iterate list of workflow_ids and get outputs**

Limitations:

    we leave behind submissions that do not have any successful workflows
    IIRC we don't have the ability to pull workflow metadata for workflows that was run over a year ago
    the script does not yet loop through the data model and capture any file paths/outputs to the final list

Developed by: Sushma Chaluvadi
Modified by: Eugenio Mattei
Maintainer: Eugenio Mattei
Broad Institute of MIT and Harvard
"""

import argparse
import json
import logging
import requests
import sys

from datetime import date
from firecloud import api as fapi
from oauth2client.client import GoogleCredentials
import time
from typing import List, Dict, Any

# Set up logging
logging.basicConfig(filename='workspace-utils-app.log', filemode='w', format='%(name)s - %(levelname)s - %(message)s')


def write_outputs_to_file(outputs_list, output_file="all_outputs.txt"):
    """Write list of outputs to file."""
    
    logging.info(f"Starting write of all outputs to {output_file}.")
    # format list to write to file
    # if item in overall list of outputs is a list, unnest it and hold in separate list
    unnested_array_items = [output for output_item in outputs_list if isinstance(output_item,list) for output in output_item]
    
    # if item in overall list of outputs is not a list, hold in separate list
    non_array_items = [output_item for output_item in outputs_list if not isinstance(output_item,list)]

    # concatenated both flattened lists together
    final_outputs_list = unnested_array_items + non_array_items

    with open(output_file, 'w') as outfile:
        # The output might be missing and Terra reports `None` type.
        # Changing it to a string to avoid error.
        outfile.write('\n'.join( [output for output in final_outputs_list if output]))


def get_workflow_outputs(ws_project, ws_name, submission_id, workflow_id):
    """Get outputs for a single workflow"""

    response = fapi.get_workflow_outputs(ws_project, ws_name, submission_id, workflow_id)
    status_code = response.status_code

    # return empty dictionary if not able to get workflow outputs
    if status_code != 200:
        return response.text, False
    
    return response.json(), True



def get_all_outputs(ws_project, ws_name, workflows_by_submission):
    """Get list of workflow outputs."""

    print(f"Starting extraction of outputs for successfully completed workflows.")
    # capture all outputs in wf level outputs
    all_outputs_list = []

    # {submission_id: [workflow_ids]}
    for submission_id, workflows in workflows_by_submission.items():
        for workflow_id in workflows:
            # get workflow's output metadata
            workflow_metadata, workflow_metadata_exists = get_workflow_outputs(ws_project, ws_name, submission_id, workflow_id)
           
            # if there is any workflow metadata - metadata for workflows over a year old is deleted
            if workflow_metadata_exists:

                # get list of keys ("task") that have an outputs section in returned workflow metadata
                all_tasks = list(workflow_metadata["tasks"].keys())
                tasks_with_outputs = [task for task in all_tasks if "outputs" in workflow_metadata["tasks"][task].keys()]

                for task in tasks_with_outputs:
                    # get workflow level outputs
                    workflow_outputs = workflow_metadata["tasks"][task]["outputs"]
                    
                    for wf_output_name, wf_output_value in workflow_outputs.items():
                        all_outputs_list.append(wf_output_value)

    return all_outputs_list


def get_succeeded_workflows(ws_project, ws_name, submissions_json, submitter_email=None, date_limit=date(1970, 1, 1)):
    """Get list of all submission ids containing Succeeded workflows and successful workflow ids."""

    print("Starting extraction of succeeded only workflows in each submission.")
    # init list to collect succeeded wf ids 
    wfs_by_submission = {}

    for sub in submissions_json:
        submission_id = sub["submissionId"]
        # get list of workflow statuses in single submission
        sub_wf_statuses = list(sub["workflowStatuses"].keys())

        # if sub. has succeeded workflows, get workflow ids
        #if  "Succeeded" in sub_wf_statuses:
            # get all workflows in successful submission
        submission_date = date.fromisoformat(sub["submissionDate"].split("T")[0])
        
        if sub["submitter"] != submitter_email:
            continue

        if submission_date < date_limit:
            print("Skipping recent submission", file=sys.stderr)
            continue
        
        all_workflows = fapi.get_submission(ws_project, ws_name, submission_id).json()["workflows"]

        # get list of successful workflow ids for submission
        successful_workflows = []
        for wf in all_workflows:
            if wf["status"] != "Succeeded" and "workflowId" in wf:
            #if "workflowId" in wf:
                successful_workflows.append(f"{wf['workflowId']}\t{sub['methodConfigurationName']}")

        
        wfs_by_submission[submission_id] = successful_workflows
                    
    # if no successful workflows in workspace
    if not wfs_by_submission:
        raise ValueError("No successful workflows across all submissions in this workspace.")
    
    return wfs_by_submission


def get_workspace_submissions(ws_project: str, ws_name: str) -> List[Dict[str, Any]]:
    """Get list of all submissions from Terra workspace.

    Args:
        ws_project (str): The project ID of the Terra workspace.
        ws_name (str): The name of the Terra workspace.

    Returns:
        list: A list of all submissions in the Terra workspace.

    Raises:
        ValueError: If no submissions are found in the specified workspace.
    """

    logging.info("Starting extraction of all submissions.")
    # get the submission data
    sub_details_json = fapi.list_submissions(ws_project, ws_name).json()

    # no submissions in workspace - returns empty list
    if not sub_details_json:
        raise ValueError(f"No submissions found in {ws_project}/{ws_name}.")

    return sub_details_json


def get_workflows_by_submission(ws_project: str, ws_name: str, submission_id: str) -> Dict[str, List[str]]:
    """
    Retrieves the workflows associated with a submission in a Terra workspace.

    Args:
        ws_project (str): The project ID of the Terra workspace.
        ws_name (str): The name of the Terra workspace.
        submission_id (str): The ID of the submission.

    Returns:
        Dict[str, List[str]]: A dictionary where the keys are the workflow names and the values are lists of workflow IDs.

    """
    return fapi.get_submission(ws_project, ws_name, submission_id).json()


def get_workflow_name(workflow_json: Dict[str, Any]) -> str:
    """
    Retrieves the name of the workflow from the JSON response.

    Args:
        json (Dict[str, Any]): The JSON response from the Terra API.

    Returns:
        str: The name of the workflow.
    """
    return workflow_json["inputResolutions"][0]["inputName"].split(".")[0]


def get_gs_links_for_failed_workflows(ws_project: str, ws_name: str, submission_id: str) -> List[str]:
    all_workflows = get_workflows_by_submission(ws_project, ws_name, submission_id)
    root = all_workflows["submissionRoot"]
    gs_paths = []
    for workflow in all_workflows["workflows"]:
        if workflow["status"] != "Succeeded" and "workflowId" in workflow:
            gs_paths.append(f"{root}/{get_workflow_name(workflow)}/{workflow['workflowId']}")
    return gs_paths





def main(ws_project, ws_name):
    parser = argparse.ArgumentParser(description='Terra workspace utility script.')
    subparsers = parser.add_subparsers()

    parser_clean = subparsers.add_parser('clean')
    parser_clean.add_argument('-p', '--project', required=True)
    parser_clean.add_argument('-w', '--workspace', required=True)
    parser_clean.add_argument('clean_type', choices=['soft-clean', 'hard-clean'])
    parser_clean.set_defaults(func=clean)

    parser_get = subparsers.add_parser('get')
    parser_get.add_argument('-p', '--project', required=True)
    parser_get.add_argument('-w', '--workspace', required=True)
    parser_get.add_argument('-e', '--email')
    parser_get.add_argument('-d', '--date')
    parser_get.set_defaults(func=get)

    args = parser.parse_args()
    args.func(args)
    """Get failed and/or aborted workflows from submission and re-ingest to TDR dataset table for WFL submission retry."""
    fh = open("submission-folders-no-succes-to-remove-gro-test.txt", "w")
    # get all submissions in workspace
    all_submissions = get_workspace_submissions(ws_project, ws_name)
    
    # get all succeeded workflows across all submissions
    succeeded_wfs_by_sub = get_succeeded_workflows(ws_project, ws_name, all_submissions)
    for sub_id, wd_id in succeeded_wfs_by_sub.items():
        for wd in wd_id:
            id = wd.split('\t')[0]
            name = wd.split('\t')[1]
            print(f"gs://fc-secure-0a879173-62d3-4c3a-8fc3-e35ee4248901/submissions/{sub_id}/placeholder/{id}\t{name}", file = fh)
    exit(0)
    
    # query each successful workflow for workflow outputs
    all_succeeded_wf_outputs = get_all_outputs(ws_project, ws_name, succeeded_wfs_by_sub)

    # write outputs to file
    write_outputs_to_file(all_succeeded_wf_outputs)

def clean(args):
    print(f"Performing {args.clean_type} clean on project {args.project} and workspace {args.workspace}")

def get(args):
    print(f"Getting data from project {args.project} and workspace {args.workspace} with filters email={args.email} and date={args.date}")

if __name__ == "__main__":

    # Generate a script that has two functionalities get and clean and will be called  like in the examples below
    # python terra-workspace-utils.py clean -p anvil-datastorage -w jamboree-gs
    # python terra-workspace-utils.py get -p anvil-datastorage -w jamboree-gs
    # the clean option will take soft-clean and hard-clean as arguments
    # the get option will take the workspace name and project as arguments and wll be able to filter by email and date
    main()





    parser = argparse.ArgumentParser(description='Create new snapshot from rows that failed a Terra workflow submission')
    
    parser.add_argument('-p', '--ws_project', required=True, help='workspace project/namespace')
    parser.add_argument('-w', '--ws_name', required=True, help='workspace name')

    args = parser.parse_args()

    main(args.ws_project, args.ws_name)