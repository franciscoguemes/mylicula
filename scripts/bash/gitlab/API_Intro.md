# GitLab API Introduction

This document provides an overview of the GitLab API endpoints, their parameters, and examples of how to call them using `curl`.

<!-- TOC -->
* [GitLab API Introduction](#gitlab-api-introduction)
  * [1. List GitLab Groups](#1-list-gitlab-groups)
    * [Endpoint](#endpoint)
    * [Parameters](#parameters)
    * [Example `curl` Command](#example-curl-command)
    * [Example Output](#example-output)
  * [2. List GitLab Projects](#2-list-gitlab-projects)
    * [Endpoint](#endpoint-1)
    * [Parameters](#parameters-1)
    * [Example `curl` Command](#example-curl-command-1)
    * [Example Output](#example-output-1)
  * [3. Fetch a Specific Group](#3-fetch-a-specific-group)
    * [Endpoint](#endpoint-2)
    * [Parameters](#parameters-2)
    * [Example `curl` Command](#example-curl-command-2)
    * [Example Output](#example-output-2)
  * [4. Fetch a Specific Project](#4-fetch-a-specific-project)
    * [Endpoint](#endpoint-3)
    * [Parameters](#parameters-3)
    * [Example `curl` Command](#example-curl-command-3)
    * [Example Output](#example-output-3)
  * [Conclusion](#conclusion)
<!-- TOC -->


## 1. List GitLab Groups

### Endpoint

```
GET /api/v4/groups
```

### Parameters
- `per_page`: Number of items to return per page (default is 20).
- `page`: Page number to retrieve (default is 1).
- `PRIVATE-TOKEN`: Your personal access token for authentication.

### Example `curl` Command
```
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups?per_page=100&page=1"
```

### Example Output
```
[
  {
    "id": 1,
    "name": "Group Name",
    "path": "group-name",
    "full_path": "namespace/group-name",
    "web_url": "https://gitlab.example.com/groups/namespace/group-name"
  },
  ...
]
```

## 2. List GitLab Projects

### Endpoint
```
GET /api/v4/projects
```

### Parameters
- `simple`: If set to true, returns a simplified version of the project.
- `per_page`: Number of items to return per page (default is 20).
- `page`: Page number to retrieve (default is 1).
- `PRIVATE-TOKEN`: Your personal access token for authentication.

### Example `curl` Command
```
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects?simple=true&per_page=100&page=1"
```

### Example Output
```
[
  {
    "id": 1,
    "name": "Project Name",
    "path": "project-name",
    "web_url": "https://gitlab.example.com/namespace/project-name"
  },
  ...
]
```

## 3. Fetch a Specific Group

### Endpoint
```
GET /api/v4/groups/:id
```

### Parameters
- `id`: The ID or URL-encoded path of the group.
- `PRIVATE-TOKEN`: Your personal access token for authentication.

### Example `curl` Command
```
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1"
```

### Example Output
```
{
  "id": 1,
  "name": "Group Name",
  "path": "group-name",
  "full_path": "namespace/group-name",
  "web_url": "https://gitlab.example.com/groups/namespace/group-name"
}
```

## 4. Fetch a Specific Project

### Endpoint
```
GET /api/v4/projects/:id
```

### Parameters
- `id`: The ID or URL-encoded path of the project.
- `PRIVATE-TOKEN`: Your personal access token for authentication.

### Example `curl` Command
```
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1"
```

### Example Output
```
{
  "id": 1,
  "name": "Project Name",
  "path": "project-name",
  "web_url": "https://gitlab.example.com/namespace/project-name"
}
```

## Conclusion

This document provides a basic introduction to some of the GitLab API endpoints. For more detailed information, please refer to the [GitLab API Documentation](https://docs.gitlab.com/ee/api/).