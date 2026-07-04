
# containerized-lambda

A **container-image AWS Lambda** (Java + Gradle + Jackson) fronted by a public
**Lambda Function URL** that echoes back the HTTP request it receives. Provisioned with Terraform.

The app has **no AWS Lambda dependency** — it runs a JDK HTTP server via its main() method. The
**AWS Lambda Web Adapter**, baked into the image as an extension, bridges Lambda's Runtime API to
the server over HTTP. This keeps the code framework-agnostic so it can later handle protocols the
Lambda handler model does not expose (response streaming, arbitrary HTTP routing, other frameworks).


# requirements
java gradle docker terraform



# local testing

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

# Staging to aws

- optional pre-step: [Create secure bucket](infra/bootstrap/README.md) for tf state if it does not yet exist.
- update <ACCOUNT_ID> in [infra/versions.tf](infra/terraform.tf) to match bucket name
- run deploy script
  ```bash
  ./deploy.sh -auto-approve
  ```
- test curl (with function_url from deploy script output)
  ```bash
  curl -s 'function_url/hello?name=alice'
  ``` 
  

