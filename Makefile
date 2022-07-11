default: build

build:
	go install

test:
	go test -parallel=4 -v ./...

testacc:
	TF_ACC=1 go test ./... -v $(TESTARGS) -timeout 120m

vet:
	go vet ./...

fmt:
	go fmt ./...

generatemocks:
	mockgen -destination=provider/mocks/lambdaclient.go -package=mocks github.com/thetradedesk/terraform-provider-lambdabased/provider LambdaClient

.PHONY: build testacc vet fmt
