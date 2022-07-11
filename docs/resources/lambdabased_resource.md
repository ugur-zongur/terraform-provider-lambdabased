# lambdabased_resource Resource

This resource enables Terraform to manage a custom resource via AWS Lambda functions. It invokes a desired lambda function upon create/update and optionally invokes another upon destoy.

## Concealing input or result

_Concealing_, here, means preventing the `input` and/or the `result` parameter(s) to be written to the terraform state file. The provider will write an empty string instead of the actual value when the respective conceal flag is enabled. There are two potential use-cases for this feature:
1. Decoupling function invocation from the input. Normally, any change in `input` parameter will trigger a lambda invocation. But you might be passing the lambda some parameters that shouldn't invoke the function everytime they chage such as short-lived credentials or maybe dates. By concealing, combined with `triggers`, you can fine-tune the lambda invocation patterns for updates by isolating the relevant parameters.
2. Security. Even though hashicorp recommends treating [state file as sensitive data](https://www.terraform.io/language/state/sensitive-data) if you use sensitive information, this might not easily suit your trust model. For instance, if you are getting a long lived credential from secret manager and sending it to lambda, you might feel uneasy that those credentials exist as a version of an S3 object forever (assuming that's your backend).


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
