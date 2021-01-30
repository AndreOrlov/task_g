# GeoTasks

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
