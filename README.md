# Terraform Module for creating Management Groups and Policies

## General

You need a folder structure which represents your management group structure.
Policies will either be stored locally or stored in a git repo (currently only AzureDevOps supported)

## Files

- management_group.json (filename is configureable by local.management_group_config_file_name) - hosting the information of the management group (see below)

- policies.json (filename is configureable by local.management_group_policy_file_name) - hosting information of the policies

### Management-Group Settings

All files (except Root Management Group) will have the same two information-fields:

- name: the name of the Management group
- parent: the name of the parent management group

The root manamgement group needs the information if it is already existing or not this is handled by the boolean field:

- existing: this value can be true or false

### Policy Settings

- policy_filename: The name of the policy-definition file
- policy_name: The Name of the policy
- display_name: Display Name of the policy
- policy_category: Category of the policy
- assignment_name: Name of the assignment

### Examples

#### Root Management Group

```json
{
    "name": "mg-root",
    "existing": true
}
```

#### Child Management Group

```json
{
    "name": "region",
    "parent": "root-mg"
}
```

#### Polices

```json
[
    {
     "policy_filename" :  "cis-10.6-res-mandatory-tags.json",
     "policy_name" : "cis-10.6-res-mandatory-tags",
     "display_name" : "cis-10.6-res-mandatory-tags",
     "policy_category" : "tags",
     "assignment_name" : "mandatorytagsres"
     
   }
]
```

## Terraform

To access and setup the Azure DevOps provider correctly, you need to provide two locals:

- git_pat - your PAT to checkout the git-repos
- org_service_url - the service URL of your Azure DevOps setup