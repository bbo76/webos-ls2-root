# Technical Analysis — webOS LS2 Root

## 1. Tested Environment

| Item                 | Value                  |
| -------------------- | ---------------------- |
| TV                   | LG OLED55C35LA (C3)    |
| Firmware version     | 43.21.96               |
| Test date            | November 1, 2026       |
| Initial access       | SSH via Developer Mode |
| SSH account          | `prisoner` (UID 5693)  |
| Homebrew Channel     | 0.7.3                  |

These observations apply to one TV. Compatibility with other webOS versions remains to be verified.

## 2. Discovery: Privileged Execution via LS2

Luna Service 2 (LS2) is the inter-service communication mechanism used by webOS.

Our experiment showed that a manifest loaded dynamically from the Developer Mode environment could register a service that ran with root privileges.

### Observed Mechanism

1. Prepare an LS2 manifest and a dynamic service definition.
2. Load the manifest from a web page running on the TV, using `PalmServiceBridge` and `com.webos.service.bus/addManifestsDir`.
3. Invoke the newly registered service.
4. Run a diagnostic script.
5. Observe `uid=0(root)` in the output.

### Observed Execution Context

- Parent process: `ls-hubd`
- Effective UID: `0`
- Effective GID: `0`
- `NoNewPrivs`: `0`
- `Seccomp`: `0`

**To determine:** why this configuration permits privileged execution and what security checks are applied when registering the manifest.

## 3. Persistence

A separate manifest was registered in `/var/luna-service2-dev`, a location scanned by LS2.

After restarting the TV, the service could be called again without manually reloading the temporary manifest.

This observation demonstrates that the registration persisted across the tested restart.

It does not demonstrate automatic execution at startup: the dynamic service is launched on demand.

## 4. Homebrew Channel Installation

The official Homebrew Channel 0.7.3 installation was performed from the obtained root context.

The installation process modified the Homebrew service definition and its LS2 permissions.

Observed results:

- Installation succeeded.
- `Root status: OK` in Homebrew Channel.
- `Root status: OK` after restarting the TV.
- Telnet was disabled by the Homebrew configuration marker.

## 5. Limitations and Open Questions

The following remain to be studied:

- Reproducibility from a clean Developer Mode environment.
- Behavior after a full power cycle.
- Behavior after a firmware update.
- Effect of disabling or expiring Developer Mode.
- Authorization checks on LS2 calls.
- Complete cleanup of experimental services.

## 6. Security Considerations

The experimental service used a script that could be modified from the Developer Mode environment but ran with root privileges.

This is a risky configuration suited to a temporary research lab, not a permanent installation.

The project should provide controlled cleanup of experimental components without modifying LG-signed scripts or files required by Homebrew Channel.
