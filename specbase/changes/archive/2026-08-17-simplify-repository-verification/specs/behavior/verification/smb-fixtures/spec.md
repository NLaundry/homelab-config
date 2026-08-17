---
id: behavior.verification.smb-fixtures
---

## Purpose

This retired pair previously described a hidden authenticated endpoint used only by repository verification machinery.

## REMOVED Requirements

### Requirement: The tester can authenticate to the verification endpoint
**ID:** `tester-authenticated`
**Reason:** The dedicated tester and hidden endpoint are test-only production machinery rather than a selected homelab capability.
**Migration:** Ordinary guest-share behavior is verified directly through `behavior.storage.nas-samba`.

### Requirement: The verification endpoint requires the testing credential
**ID:** `tester-credential-required`
**Reason:** The credential and endpoint are retired together.
**Migration:** No replacement credential boundary is introduced.

### Requirement: The tester can complete a disposable fixture transaction
**ID:** `fixture-transaction`
**Reason:** The hidden transaction does not prove ordinary user-facing SMB behavior.
**Migration:** Bounded guest transactions run directly against `mediaBin` and `smolBoy`.

### Requirement: Accepted mutations are attributable
**ID:** `mutation-attribution`
**Reason:** Dedicated audit attribution existed solely for the retired test identity and fixture endpoint.
**Migration:** Ordinary guest-share verification remains exactly scoped and cleanup-safe but does not retain a separate audit subsystem.
