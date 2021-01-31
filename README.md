# GeoTasks

## Notes about implementation

1. Geo-spatial requests like points in the circle are pretty implemented in `PostGIS` extension
   of Postgre database or `GEORADIUS` command of Redis database. But clean Postgre suggested as a
   database so I decide to implement this by myself using geo-hashes. If this solution is not
   appropriate futher benchmarks should be done to find a fastest way.
2. In more complex systems database repo logic usually implemented in separate module for better
   abstraction. I decide to keep this logic in contollers for simplicity.


## Local workflow testing

Assuming application started:

```bash
# Generate manager and driver tokens and store it in env var
export M_TOKEN=`curl http://localhost:4000/token/manager -s`
export D_TOKEN=`curl http://localhost:4000/token/driver -s`

# Create task
curl -X POST \
-H "Content-Type:application/json" \
-H "Authorization:$M_TOKEN" \
--data '{"pickup":{"lat":54.630050,"lon":39.732979},"delivery":{"lat":54.630138,"lon":39.724679}}' \
http://localhost:4000/api/v1/tasks
# => {"id":"e3036fe1-5fac-4f69-9874-2b72dade5789"}

# Get task list
curl -X POST \
-H "Content-Type:application/json" \
-H "Authorization:$D_TOKEN" \
--data '{"lat":54.630050,"lon":39.732979}' \
http://localhost:4000/api/v1/tasks/nearest
# => [{"delivery":{"lat":54.630138,"lon":39.724679},"distance":0.0,"id":"e3036fe1-5fac-4f69-9874-2b72dade5789", ...

# Pickup task
curl -X POST \
-H "Content-Type:application/json" \
-H "Authorization:$D_TOKEN" \
--data '{"task_id":"e3036fe1-5fac-4f69-9874-2b72dade5789"}' \
http://localhost:4000/api/v1/tasks/pickup
# => {"id":"e3036fe1-5fac-4f69-9874-2b72dade5789","status":"assigned","updated_at":"2021-01-31T15:46:36"}

# Finish task
curl -X POST \
-H "Content-Type:application/json" \
-H "Authorization:$D_TOKEN" \
--data '{"task_id":"e3036fe1-5fac-4f69-9874-2b72dade5789"}' \
http://localhost:4000/api/v1/tasks/finish
# => {"id":"e3036fe1-5fac-4f69-9874-2b72dade5789","status":"done","updated_at":"2021-01-31T15:47:22"}
```

> NOTE: to generate tokens in production use `GeoTasks.ReleaseTasks.generate_token/1

## Local production workflow testing

```bash
# build production image
docker build -t geo_tasks .
# run docker-compose
docker-compose -f docker-compose.prod.yml
# connect to geo_tasks app
docker-compose -f docker-compose.prod.yml exec geo_tasks /geo_tasks/bin/geo_tasks remote
# run migrations
> GeoTasks.ReleaseTasks.migrate
# generate tokens
> GeoTasks.ReleaseTasks.generate_token "manager"
> GeoTasks.ReleaseTasks.generate_token "driver"
# exit from iex and copy tokens to env vars
export M_TOKEN="<manager token>"
export D_TOKEN="<driver token>"
# follow previous workflow except two first steps
```

## Local development

```bash
docker-compose up -d
iex -S mix
```

## Local testing

> NOTE: Run tests before pushing changes to repo

```bash
docker-compose -f docker-compose.test.yml up -d
mix test
```

## Local code climate

> NOTE: Run these checks before pushing changes to repo

```bash
mix credo --strict
mix dialyzer
```
