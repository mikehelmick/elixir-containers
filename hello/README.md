# Hello World - Elixir Sample

A simple web application written in Elixir using the phoenix framework.
The application prints all environment variables to the main page.

# Set up Elixir and Phoenix Locally

Following the [Phoenix Installation Guide](https://hexdocs.pm/phoenix/installation.html)
is the best way to get your computer set up for developing,
building, running, and packaging Elixir Web applications.

# Running Locally

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# Recreating the sample code

1. Generate a new project.

```$ mix phoenix.new helloelixir
```

  When asked, if you want to `Fetch and install dependencies? [Yn]` select `y`

2. Follow the direction in the output to change directories into
   start your local server with `mix phoenix.server`

3. In the new directory, create a new Dockerfile for packaging
   your application for deployment

   ```docker
   # Start from a base image for elixir
   FROM elixir:alpine

   # Set up Elixir and Phoenix
   ARG APP_NAME=hello
   ARG PHOENIX_SUBDIR=.
   ENV MIX_ENV=prod REPLACE_OS_VARS=true TERM=xterm
   WORKDIR /opt/app

   # Compile assets.
   RUN apk update \
       && apk --no-cache --update add nodejs nodejs-npm \
       && mix local.rebar --force \
       && mix local.hex --force
   COPY . .

   # Download and compile dependencies, then compile Web app.
   RUN mix do deps.get, deps.compile, compile
   RUN cd ${PHOENIX_SUBDIR}/assets \
       && npm install \
       && ./node_modules/brunch/bin/brunch build -p \
       && cd .. \
       && mix phx.digest

   # Create a release version of the application
   RUN mix release --env=prod --verbose \
       && mv _build/prod/rel/${APP_NAME} /opt/release \
       && mv /opt/release/bin/${APP_NAME} /opt/release/bin/start_server

   # Prepare final layer
   FROM alpine:latest
   RUN apk update && apk --no-cache --update add bash openssl-dev
   ENV PORT=8080 MIX_ENV=prod REPLACE_OS_VARS=true
   WORKDIR /opt/app

   # Document that the service listens on port 8080.
   EXPOSE 8080
   COPY --from=0 /opt/release .
   ENV RUNNER_LOG_DIR /var/log

   # Command to execute the application.
   CMD ["/opt/app/bin/start_server", "foreground", "boot_var=/tmp"]
   ```

4. Create a new file, `service.yaml` and copy the following Service
   definition into the file. Make sure to replace `{username}` with
   your Docker Hub username.

   ```yaml
   apiVersion: serving.knative.dev/v1alpha1
   kind: Service
   metadata:
     name: helloworld-elixir
     namespace: default
   spec:
     runLatest:
       configuration:
         revisionTemplate:
           spec:
             container:
               image: docker.io/{username}/helloworld-elixir
               env:
               - name: TARGET
                 value: "elixir Sample v1"
    ```

# Building and deploying the sample

The sample in this directory is ready to build and deploy without changes.
You can deploy the sample as is, or use you created version following the
directions above.

1. Use Docker to build the sample code into a container. To build and push
   with Docker Hub, run these commands replacing `{username}` with your Docker
   Hub username:

   ```shell
   # Build the container on your local machine.
   
