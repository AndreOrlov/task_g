# GeoTasks

## Notes about implementation

1. Geo-spatial requests like points in the circle are pretty implemented in `PostGIS` extension
   of Postgre database or `GEORADIUS` command of Redis database. But clean Postgre suggested as a
   database so I decide to implement this by myself using geo-hashes. If this solution is not
   appropriate futher benchmarks should be done to find a fastest way.
2. In more complex systems database repo logic usually implemented in separate module for better
   abstraction. I decide to keep this logic in contollers for simplicity.

## Local deveopment

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
