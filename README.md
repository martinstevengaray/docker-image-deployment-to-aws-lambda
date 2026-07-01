
# containerized-lambda

A **container-image AWS Lambda** (Java + Gradle + Jackson) fronted by a public
**Lambda Function URL** that echoes back the HTTP request it receives. Provisioned with Terraform.

The app has **no AWS Lambda dependency** — it's a plain `main()` running a JDK HTTP server. The
**AWS Lambda Web Adapter**, baked into the image as an extension, bridges Lambda's Runtime API to
the server over HTTP. This keeps the code framework-agnostic so it can later handle protocols the
Lambda handler model doesn't expose (response streaming, arbitrary HTTP routing, other frameworks).


# requirements
java gradle docker



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







## What's here

| Path | Purpose |
| --- | --- |
| `src/main/java/com/mgaray/server/Server.java` | `main()` HTTP echo server — `com.sun.net.httpserver` + Jackson, no AWS deps |
| `build.gradle`, `settings.gradle` | Gradle build; runnable jar + `copyDeps` stages dependency jars |
| `Dockerfile` | Multi-stage: Gradle build → Lambda Web Adapter → `amazoncorretto:21` runtime |
| `infra/` | Terraform: ECR repo, image build/push, IAM role, Lambda, Function URL |

The server returns a JSON body echoing the request method, path, query string, headers, and body
for any route/method.

## Prerequisites

- **Docker** running
- **AWS CLI** configured with credentials: `aws sts get-caller-identity`
- **Terraform** `>= 1.5`: `brew install terraform`
- Local Java/Gradle are **not** needed — the Dockerfile builds the app in a Gradle stage.

> On Apple Silicon the default `architecture = "arm64"` builds natively. To deploy x86_64,
> set `-var architecture=x86_64`.

## Deploy

```bash
cd infra
terraform init
terraform apply
```

A single `apply` creates the ECR repo, builds + pushes the image (via Docker), then creates the
Lambda and its public Function URL.

## Test

```bash
cd infra
URL=$(terraform output -raw function_url)
curl -s "${URL}hello?foo=bar" -H 'X-Demo: 1' -d '{"ping":"pong"}' | jq
```

Expected: a JSON body echoing `method=POST`, `path=/hello`, `queryString=foo=bar`, the request
headers, and `body={"ping":"pong"}`.

## Tear down

```bash
cd infra
terraform destroy
```

The ECR repo uses `force_delete = true`, so pushed images don't block destruction.

## Run the container locally (optional)

Because it's a normal web server, you can run it without Lambda at all:

```bash
docker build --target build -t echo-build .   # or build the full image
java -jar build/libs/*.jar   # if you have a local JDK 21
# then: curl -s localhost:8080/hello?foo=bar -d '{"ping":"pong"}' | jq
```

## Notes

- **No AWS Lambda SDK.** The only dependency is Jackson; the app talks plain HTTP. The Lambda Web
  Adapter (`/opt/extensions/lambda-adapter`) is what speaks the Lambda Runtime API.
- The adapter's readiness check (`GET /`) is satisfied by the echo handler, which answers any route.
- To pin a different adapter version, bump the `public.ecr.aws/awsguru/aws-lambda-adapter` tag in
  the `Dockerfile`.
- Re-running `terraform apply` after editing `src/`, `Dockerfile`, or the Gradle files rebuilds
  and pushes a new image tag (derived from a source hash) and updates the Lambda automatically.
