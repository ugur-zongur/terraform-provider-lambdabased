# lambdabased Provider

This provider exposes a resource to enable managing custom resources via AWS Lambda functions.

## Example Usage

```hcl
terraform {
  required_providers {
    lambdabased = {
      source  = "thetradedesk/lambdabased"
    }
  }
}

provider "lambdabased" {
  region = "us-east-1"
}
```


## Schema

- `region` (String) - (Optional) The AWS region where the provider will operate. The region must be set. Can also be set with either the `AWS_REGION` or `AWS_DEFAULT_REGION` environment variables, or via a shared config file parameter `region` if `profile` is used. If credentials are retrieved from the EC2 Instance Metadata Service, the region can also be retrieved from the metadata.
- `profile` (String) -  (Optional) AWS profile name as set in the shared configuration and credentials files. Can also be set using either the environment variables `AWS_PROFILE` or `AWS_DEFAULT_PROFILE`.
- `assume_role` - (Optional) Configuration block for assuming an IAM role. Only one `assume_role` block may be in the configuration.
  - `role_arn` - (Required) Amazon Resource Name (ARN) of the IAM Role to assume.
