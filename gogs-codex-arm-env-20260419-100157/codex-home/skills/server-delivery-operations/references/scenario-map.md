# Scenario Map

## Purpose

Use this reference to quickly choose the right remote delivery pattern before you start typing commands.

## Scenario 1: Systemd Service Delivery

Use this when:

1. the app runs directly on the host
2. a package, binary, or config file is being updated
3. `systemctl` is the lifecycle owner

Typical stage chain:

1. preflight
2. install or upload
3. config validation
4. service restart
5. local verification
6. public verification

Strong signals:

1. `systemctl is-active --quiet <service>`
2. app-specific config test
3. expected listener exists
4. health endpoint returns expected response

## Scenario 2: Docker Compose Delivery

Use this when:

1. the app is containerized
2. `docker compose` is the lifecycle owner
3. env files, compose files, and volumes are part of the deploy surface

Typical stage chain:

1. preflight
2. render or upload compose assets
3. `docker compose pull`
4. `docker compose up -d`
5. container-state verification
6. local or public endpoint verification

Strong signals:

1. `docker compose ps --services --status running`
2. required env and compose files exist
3. expected port or health endpoint responds

## Scenario 3: Reverse Proxy Fronting Multiple Services

Use this when:

1. one edge service fronts multiple upstreams
2. host-based routing or path-based routing matters
3. WebSockets or TLS termination are part of the stack

Typical stage chain:

1. preflight
2. render proxy config
3. syntax validation
4. proxy reload or restart
5. host-route verification
6. upstream-specific endpoint verification

Strong signals:

1. proxy config syntax test passes
2. TLS listener is active
3. expected host routes hit the expected upstream
4. apps that need WebSockets still work

## Scenario 4: Cleanup Or Rollback

Use this when:

1. a failed deploy must be reverted
2. project-owned resources need removal
3. the server also hosts unrelated workloads

Typical stage chain:

1. snapshot protected workloads
2. stop project-owned services
3. remove only attributable resources
4. compare protected workloads before and after
5. record rollback evidence

Strong signals:

1. removed service is absent or stopped
2. protected containers or services still match expected state
3. rollback evidence is written to logs or docs

## Safety Filters Before Any Mutation

Check these every time:

1. what package manager and init system does the host use
2. what ports are already occupied
3. what containers or services are already running
4. what directories contain durable data
5. what absolutely must not be changed
