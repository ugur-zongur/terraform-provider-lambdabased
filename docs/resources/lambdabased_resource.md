# lambdabased_resource Resource

Simply put, this resource invokes AWS Lambda functions. However, it is different than the `aws_lambda_invocation` [resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_invocation) or [data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_invocation) since it is specifically tailored to manage underlying resources. It invokes a desired lambda function upon create/update and optionally invokes another upon destroy. It also enables concealing input and output for security purposes and/or fine tuning the function triggering patterns.

Here is a real-life use-case to inspire and throw light on how this can be useful: We, as [The Trade Desk](https://www.thetradedesk.com/), employ `lambdabased_resource` to manipulate kubernetes resources in private EKS clusters. We achieve this by creating a helper lambda function within the same VPC where our private EKS cluster resides -- to be accurate, the cluster's control plane ENIs. This lambda receives temporary kubernetes access tokens along with arguments such as the helm chart parameters or the kubernetes namespace to install to. We can also uninstall the chart when the `lambdabased_resource` gets deleted.

## Concealing input or result

_Concealing_, here, means preventing the `input` and/or the `result` parameter(s) to be written to the terraform state file. The provider will write an empty string instead of the actual value when the respective conceal flag is enabled. There are two potential use-cases for this feature:
1. __Decoupling function invocation from the input.__ Normally, any change in `input` parameter will trigger a lambda invocation. But you might be passing the lambda some parameters that shouldn't invoke the function everytime they chage such as short-lived credentials. By concealing, combined with `triggers`, you can fine-tune the lambda invocation patterns for updates by isolating the relevant parameters.
2. __Security.__ Even though hashicorp recommends treating [state file as sensitive data](https://www.terraform.io/language/state/sensitive-data), this might not easily fit your trust model. For instance, if you are getting a long lived credential from secret manager and sending it to lambda, you might feel uneasy that those credentials exist as a version of an S3 object forever (assuming that's your backend). In that case, you can set `conceal_input` and provide the cryptographic hash (see [sha256](https://www.terraform.io/language/functions/sha256)) of the input to `triggers`.

## Advantages over `aws_lambda_invocation`

`lambdabased_resource` resembles `aws_lambda_invocation` [resource](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_invocation) and [data source](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lambda_invocation) as all three invokes lambda functions one way or another. Therefore it would be beneficial to point out why `lambdabased_resource` exists and what it solves explicitly. The advantages here are mostly applicable if your use-case is managing some resources using lambda functions. Otherwise `aws_lambda_invocation` might be perfectly suitable for your needs.

### `aws_lambda_invocation` resource
- `aws_lambda_invocation` gets recreated when any of its parameters is changed. This results in _destroy_s in plans which generally requires more attention from both human or machine reviewers. On the other hand `aws_lambda_invocation` updates the resource therefore the underlying semantics are more faithfully represented.
- `aws_lambda_invocation` is triggered when any part of `input` is changed. If you have some part of input that shouldn't trigger an update (e.g. a temporary access token) then this results in chatty plans. `aws_lambda_invocation` enables you to decouple triggering from input via `triggers` and `conceal_input` parameters.
- `aws_lambda_invocation` writes its input to the terraform state file as clear text therefore even though it is stored with server-side-encryption people who have access to it can see the input. If your threat model is not compatible with that, i.e. entities that have read access to the state file shouldn't see the input to the lambda, you can conceal the input and result using the `lambdabased_resource`.

### `aws_lambda_invocation` data source
- Being a data source, `aws_lambda_invocation` runs also on plans. Therefore if your lambda has side effects, they are reflected during the _plan_ phase rather than the _apply_ phase.

## Example Usage

```hcl
resource "lambdabased_resource" "test" {
    function_name = "test-function"
    triggers = {
      trigger_a = "a-trigger-value"
    }
    input = jsonencode({
        param = "a-parameter-value"
    })
    conceal_input = true
    conceal_result = true
    finalizer {
        function_name = "finalizer-test-function"
        input = jsonencode({
            param = "parameter-destroy-value"
        })
    }
}
```

## Argument Reference

- `function_name` (String) - Name of the lambda function to be executed to create/update the underlying resource.
- `qualifier` (String) - (Optional) Qualifier (i.e., version) of the lambda function. Defaults to `$LATEST`.
- `triggers` (Map of Strings) - (Optional) A map of arbitrary strings that, when changed, will force the lambda to be executed again.
- `input` (String) - JSON payload to the lambda function.
- `conceal_input` (Boolean) - If true, prevents input to be written in terraform state file. This can be used to prevent invocation upon input change and/or for security reasons.
- `conceal_result` (Boolean) - If true, prevents result to be written in terraform state file. This can be used for security reasons.
- `finalizer` - (Optional) A finalizer function that will be called upon destroy can be described using this block. Only one `finalizer` block may be in the configuration.
  - `function_name` (String) - Name of the lambda function.
  - `qualifier` (String) - (Optional) Qualifier (i.e., version) of the lambda function. Defaults to `$LATEST`.
  - `input` (String) - JSON payload to the lambda function.

## Attribute Reference

- `result` (String) - If not concealed with `conceal_result` parameter, this attribute contains the result of the last lambda function invocation.
