# Terraform Lambda-Based-Resource Provider

The Lambda-Based-Resource Provider is a plugin for Terraform that allows managing custom resources via AWS Lambda functions. This provider is maintained by The Trade Desk.

For a more comprehensive explanation see [lambdabased_resource](./docs/resources/lambdabased_resource.md) documentation.

## Usage

```hcl
terraform {
  required_providers {
    lambdabased = {
      source  = "thetradedesk/lambdabased"
      version = "~> 1.0"
    }
  }
}

provider "lambdabased" {
  region = "us-east-1"
}
```

See the complete example [here](./examples/default)

## Testing

```shell
make test
```
