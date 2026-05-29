Run a pre-release deployment checklist. This catches the categories of failure that occurred in the v2.1.1 incident (see `.claude/incidents/002-v2.1.1-release-deployment-failures.md`).

Run each check, report the result, and stop if anything fails before proceeding to deploy.

---

## Check 1 — Directory name references

Old path `tmbr/` was renamed to `tmbr-web/`. Any stale reference breaks the Heroku build.

```bash
grep -r '"tmbr"' tmbr-web/Package.swift tmbr-web/Sources/ tmbr-web/Tests/ || echo "OK"
grep -rn 'workingDirectory.*"tmbr"' tmbr-web/Sources/ || echo "OK"
```

Report any matches as blocking.

## Check 2 — Force-unwrapped environment variables

A missing env var with a force-unwrap crashes at startup with no useful error message.

```bash
grep -rn 'Environment\.get.*!' tmbr-web/Sources/ || echo "OK"
```

Report any matches. Each should either be optional-chained with a fallback or throw a clear error on startup.

## Check 3 — Apple-only framework imports in tmbr-core

`tmbr-core` must compile on Linux. Apple-only imports break the server build.

```bash
grep -rn '^import ' tmbr-core/Sources/ | grep -v 'Foundation\|Swift ' || echo "OK"
```

Also build tmbr-core standalone:
```bash
swift build --package-path tmbr-core
```

Report any non-Foundation/Swift imports or build failures as blocking.

## Check 4 — Heroku PACKAGE_DIR config var

The Heroku buildpack uses `PACKAGE_DIR` to find the Swift package. It must match the current directory name.

```bash
heroku config:get PACKAGE_DIR --app tmbr-production
```

Expected: `tmbr-web`. Report if it's anything else.

## Check 5 — Required environment variables

Check that all required env vars are set on production. Missing vars crash at startup (or silently degrade if optional).

```bash
heroku config --app tmbr-production
```

Verify at minimum:
- `DATABASE_URL`
- `SIWA_NATIVE_APP_ID` (Sign In with Apple — force-unwrapped, must be present)
- `SESSION_SECRET` or equivalent
- `PACKAGE_DIR` (checked above)

Report any that are absent.

## Check 6 — Staging smoke test

If a staging app exists tracking `main`:

```bash
heroku releases --app tmbr-staging | head -5
```

Confirm the latest release is healthy (no crash-loop). Check logs for startup errors:

```bash
heroku logs --tail --app tmbr-staging
```

---

## Deploy

Only proceed after all checks pass. If any check fails, fix it and re-run the checklist before deploying.

```bash
git push heroku main
heroku logs --tail --app tmbr-production
```

Watch logs for successful startup (migration applied, server listening). Report any errors.
