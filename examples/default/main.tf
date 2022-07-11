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

resource "lambdabased_resource" "test" {
    function_name = "test-function"
    triggers = { trig_a = "dummy-trigger" }
    input = jsonencode({
        param = "parameter-value"
    })
    conceal_input = true
    conceal_result = true
    finalizer {
        function_name = "test-function"
        input = jsonencode({
            param = "parameter-destroy-value"
        })
    }
}
