# Testing Email Receipt

Many services send emails, whether transactional or automated, but far fewer test the full workflow, including the payload delivered through the SMTP connection. This project provides tools to allow for automated testing of **email receipt**, not only the pre-send payload.

## Overview

This project consists of a docker container with two major moving pieces, both of which are customizable.

### POSTFIX Email Server

When the container is running, it houses a running POSTFIX server to which you can connect with SMTP requests to send full email payloads. The easiest way to test this is to connect directly with telnet and watch the logs verify communication.

#### Configuration

You can override or modify the baseline configuration for your email handling in one of two ways:

##### Alter `.cf` files

These are the core files that are used to define the receipt rules:

* `conf/main.cf`
* `conf/master.cf`
* `conf/redirect.regexp`
* `conf/transport`

By modifying these files directly, you can set up multiple, specific transport mappings rather than the single, generic mapping.

#### ENV variables

The docker container provides the `HOSTNAME` and `DOMAIN` variables that define which messages POSTFIX will acknowledge. If you want to test against domain `example.com`, you might provide the following environment overrides to your `docker run` command:

* `-e "DOMAIN=example.com"`
* `-e "HOSTNAME=mail.example.com"`

With these in place, any inbound messages to `*@example.com` will be allowed and handled by the email server.

### Custom Handler Script

With no customization, the default transport will pipe all emails received through the script found at `app/router.js`. This script needs to be modified or extended to handle your use case. 

The script will receive both the sender and recipient addresses through `ARGV`, and the entirety of the email content will be received through `STDIN`.

## Getting Started

#### Clone repo and build docker image

```sh
$ git clone <repository>
$ cd docker-node-postfix
$ ./build
```

#### Run the docker image

When you run your container, be sure to provide any environment overrides and map your container's port 25 to one to which you can connect.

Let's start by specifying our `PORT` for simplicity:

```sh
$ export PORT=1337
```

Now, run the container:

```sh
$ docker run -i -p $PORT:25 \
  -t guahanweb/docker-node-postfix:0.0.1 \
  -e "HOSTNAME=mail.example.com" \
  -e "DOMAIN=example.com"
```

#### Connect via telnet and send a test message

Now, we can connect via telnet and send a test message. I am adding `>` and `<` to the beginning of the lines to indicate which are inbound and outbound messages.

```
$ telnet localhost $PORT
< Trying ::1...
< Connected to localhost.
< Escape character is '^]'.
< 220 mail.example.com ESMTP Postfix

> HELO example.com
< 250 mail.example.com

> MAIL FROM:<test@guahanweb.com>
< 250 2.1.0 Ok

> RCPT TO:<foobar@example.com>
< 250 2.1.5 Ok

> DATA
< 354 End data with <CR><LF>.<CR><LF>
> Subject: test message
> 
> Here is the content of your email!
> 
> .
< 250 2.0.0 Ok: queued as 0D8DE94
```

#### Check logs to be sure mail was handled

Since the default script just logs traffic, we need to bash into the container and view our logs.

First, note your container ID.

```sh
$ docker ps
CONTAINER ID        IMAGE                                 COMMAND             CREATED             STATUS              PORTS                  NAMES
a6eae1915c7a        guahanweb/docker-node-postfix:0.0.1   "/start.sh"         23 seconds ago      Up 22 seconds       0.0.0.0:1337->25/tcp   stupefied_wright
```

Now, execute bash on the container ID to see the logs and verify your email was received.

```sh
$ docker exec -it a6eae1915c7a bash
bash-4.3# cat logs/2017-06-22.log
2017-06-22 21:05:29 [INFO] Initialized script with env: {"LANG":"C","PATH":"/usr/local/bin:/bin:/usr/bin"}
2017-06-22 21:05:29 [INFO] Called with args: ["/usr/bin/node","/app/router.js","test@guahanweb.com","foobar@example.com"]
```

Notice that the log files are grouped by day, so be sure to monitor the appropriate file, especially if you are using a persistent volume.
