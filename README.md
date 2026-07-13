
# Containerized AWS Lambda

Lambda running a simple Java HTTP server via a main method, packaged as a Docker container image instead of the standard RequestHandler.handleRequest() setup. This same image runs unchanged locally or on other container platforms, and can include tools a standard Lambda runtime doesn't provide. The AWS Lambda Web Adapter is baked into the image as an extension and bridges Lambda's Runtime API to the containerized server over HTTP.

# Requirements
* AWS account
* java, gradle, docker, terraform

# Setup
1) Create an S3 bucket to hold terraform state [create-tfstate-bucket.sh](https://github.com/martinstevengaray/bootstrap-utilities/blob/main/infra/create-tfstate-bucket.sh) if one does not already exist.
2) Create new configuration script at: ./local/deployment-config.sh
```bash
export TERRAFORM_TFSTATE_S3_BUCKET="<your terraform tfstate s3 bucket>"
export TERRAFORM_TFSTATE_S3_REGION="<your terraform tfstate s3 region>"
export DEPLOYMENT_REGION="<your deployment region>"
export ECR_REGISTRY="<account-id>.dkr.ecr.<region>.amazonaws.com" #must be in same region as DEPLOYMENT_REGION
export ECR_REPOSITORY="<your ecr repository>"
export LAMBDA_FUNCTION_NAME="<your lambda function name>"
```
3) Deploy lambda and associated infrastructure with [deploy.sh](deploy.sh) -auto-approve
4) Test with curl (using function_url as output from deploy.sh in previous step)
```bash
curl -s '<function_url>/hello?name=alice'
```

## optional local testing

START server locally without docker:
```bash
./gradlew build
java -cp "build/libs/containerized-lambda.jar:build/dependency/*" com.mgaray.server.Server
```

START server locally with docker:
```bash
docker build -t containerized-lambda .
docker run --rm -p 8080:8080 containerized-lambda
```

GET:
```bash
curl -s 'http://localhost:8080/hello?name=alice'
```
POST (json):
```bash
curl -s -X POST 'http://localhost:8080/submit?source=cli' \
-H 'Content-Type: application/json' \
-d '{"name":"alice","greeting":"hello"}'
```
POST (form-encoded):
```bash
curl -s -X POST 'http://localhost:8080/submit' \
-H 'Content-Type: application/x-www-form-urlencoded' \
-d 'name=alice&greeting=hello'
```


