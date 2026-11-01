# webos-ls2-root

Experimental research project exploring LS2 service execution
and root access on LG webOS televisions.

## Verified environment

- TV: LG OLED55C35LA (C3)
- Firmware: 43.21.96
- Developer Mode: enabled
- Root execution via LS2: confirmed
- Persistence across TV restart: confirmed
- Homebrew Channel 0.7.3: root status OK after restart

## Goals

1. Document the LS2 behavior and prerequisites
2. Build reproducible diagnostics
3. Validate Homebrew Channel installation
4. Test persistence and compatibility
5. Provide safe cleanup and recovery procedures

## Status

Experimental. Validated on one television only.

No automatic boot execution or full cold-power-cycle
persistence has been demonstrated yet.

## Safety

For authorized research on personally owned devices.
Do not modify LG-signed Developer Mode components.
