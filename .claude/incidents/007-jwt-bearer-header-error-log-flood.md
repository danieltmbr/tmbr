# Incident: ERROR log flood — "Request is missing JWT bearer header" on every unauthenticated request

**Date**: 2026-07-08
**Severity**: Low
**Status**: Resolved

## What happened

Production logs were flooded with `[ ERROR ] Request is missing JWT bearer header.` on every request that carried no Authorization header — including public endpoints that require no authentication. No functional impact, but the noise buried real errors.

## Root cause

`AppleSignInTokenParser` (web-auth) is registered as a **global** middleware in `tmbr-web/Sources/App/configure.swift`, so it runs on every request. It called the no-argument `request.jwt.apple.verify()` from vapor/jwt, which — when the Bearer header is absent — logs at `.error` level *before* throwing (`JWT+Apple.swift` in the dependency). The middleware's `try?` correctly swallowed the throw (optional-auth pattern), but the log line is emitted inside the library before the throw, so `try?` could not suppress it.

## How it was fixed

The middleware now extracts the Bearer token itself and only calls the explicit `verify(token)` overload when a token is present, skipping the library's missing-header log path entirely:

```swift
if let token = request.headers.bearerAuthorization?.token,
   let identity = try? await request.jwt.apple.verify(token),
   ...
```

Behavior is unchanged: requests without a header continue anonymously; valid tokens still log the user in. Invalid tokens may still log inside `verify(token)` — acceptable, since an invalid token is a genuine anomaly.

## Prevention

- [x] New test: unauthenticated request through the middleware passes through with zero error-level logs
- [x] Process/doc change: none — lesson recorded here: in optional-auth middleware, extract the credential yourself before calling library verifiers; library convenience methods may log at ERROR before throwing, and `try?` cannot suppress logs
- [ ] Long-term fix if current solution is a workaround: n/a — this is the proper fix

## Tests added

`web-auth/Tests/WebAuthTests/AppleSignInTokenParserTests.swift` — new WebAuthTests target (the package previously had none). Boots a minimal Vapor app with the middleware, a capturing `LogHandler`, and a public route; asserts the request succeeds and no error-level log is emitted. Verified the test fails against the pre-fix middleware with the exact production log line.
