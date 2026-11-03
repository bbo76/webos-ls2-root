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

## Getting started

> [!WARNING]
> This is experimental research software, validated on only one LG TV and firmware version. Use it only on a device you own or are authorized to test. The procedure may not work on other webOS versions.

### Prerequisites

- A **macOS or Linux** machine, or **Windows with WSL**, with Git, Bash, OpenSSH, Python 3, Node.js/npm, and the current official **`@webos-tools/cli`** for initial Developer Mode SSH setup. The scripts also use `curl`, `openssl`, `lsof`, and SHA-256 utilities. **Platform caveat:** `deploy.sh` currently calls `shasum -a 256` (install `shasum` on Linux/WSL if missing), while `install.sh` uses macOS-specific `ipconfig getifaddr en0` for automatic IP detection. On Linux/WSL, set `MAC_IP` explicitly; the TV must be able to reach that address. Native Windows shells are not supported by these Bash scripts without adaptation.
- An LG webOS TV with **Developer Mode enabled** and a working **SSH connection** from your computer. Developer Mode SSH access does **not** itself mean you have root access.
- Your computer and TV connected to a network that permits SSH to the TV. For the interactive bootstrap, the TV must also be able to reach an HTTP server on your computer (default port `8765`).
- A working SSH host alias (default: `lg-tv`), or an explicit `TV_HOST` environment variable.

### 1. Clone the repository

```bash
git clone https://github.com/bbo76/webos-ls2-root.git
cd webos-ls2-root
```

### 2. Install LG's current webOS CLI and retrieve the Developer Mode key

Install the current LG **webOS CLI** package (`@webos-tools/cli`), not the older `@webosose/ares-cli` or legacy webOS TV CLI. The new CLI still uses `ares-*` command names.

```bash
npm install -g @webos-tools/cli
ares-config --profile tv
ares-setup-device
```

On the TV, open the **Developer Mode** app, enable Developer Mode and **Key Server**, and note its IP address and the passphrase shown in the app. In `ares-setup-device`, register the TV using its actual IP address and Developer Mode SSH settings (commonly user `prisoner` and port `9922`). Choose a device name such as `lg-tv`.

Retrieve the private key for that registered device:

```bash
ares-novacom --device lg-tv --getkey
```

Enter the **Developer Mode passphrase shown on the TV** when prompted. Note the local key path reported by the CLI. This retrieves the TV's Developer Mode SSH key; it is **not** the same as generating a new key with `ssh-keygen`. The passphrase is used for key retrieval, not as the regular SSH login password.

### 3. Set up and test SSH access

Configure your TV's Developer Mode SSH credentials in `~/.ssh/config`, for example:

```sshconfig
Host lg-tv
    HostName 192.168.1.100
    User prisoner
    Port 9922
    IdentityFile ~/.ssh/webos_key
    IdentitiesOnly yes
    BatchMode yes
    ConnectTimeout 10
```

Replace the IP address, username, port, and especially the `IdentityFile` path with the values from your actual Developer Mode and CLI setup. The example is **not** a universal TV configuration. `IdentitiesOnly yes` restricts authentication to the configured identity, `BatchMode yes` disables interactive password/passphrase prompts, and `ConnectTimeout 10` prevents long connection hangs. These options do not create or authorize an SSH key: the correct key must already be configured and usable without prompting (for example, an unencrypted Developer Mode key or a key already unlocked in an SSH agent). Keep SSH host-key verification enabled; accept and verify the TV's host key during the initial interactive connection.

```bash
ssh lg-tv 'id'
```

Before running either script, make sure key-based authentication works without an interactive prompt:

```bash
ssh -o BatchMode=yes lg-tv 'echo "SSH OK"'
```

Alternatively, point the scripts at another host or SSH alias with `TV_HOST`:

```bash
export TV_HOST=lg-tv
```

### 4. Deploy the diagnostic files

Run from the repository root:

```bash
bash scripts/deploy.sh
```

Or, using a different SSH host alias:

```bash
TV_HOST=my-webos-tv bash scripts/deploy.sh
```

The deployment script copies three files to the TV under `/media/developer/temp/ls2root-v01/`:

| Local file | Remote destination |
| --- | --- |
| `bootstrap/manifest.json` | `reference-test/manifest.json` |
| `bootstrap/service` | `services/com.example.ls2root.v01.service` |
| `bootstrap/verify-root.sh` | `verify-root.sh` |

It creates the remote directories, checks SHA-256 hashes after each upload, and marks the verification script executable.

**Important:** `deploy.sh` only stages files. It does **not** register the LS2 manifest, grant root access, or install Homebrew Channel. Successful deployment only means the files arrived intact.

### 5. Register the manifest and verify execution

For the interactive bootstrap, use the higher-level installer from the repository root:

```bash
bash scripts/install.sh
```

On Linux/WSL, or if macOS cannot detect the correct address via `en0`, set `MAC_IP` explicitly (use the address reachable **from the TV**):

```bash
MAC_IP=192.168.1.50 bash scripts/install.sh
```

You can also override `TV_HOST` and `BOOTSTRAP_PORT` (default `8765`).

When the diagnostic is not yet operational, `install.sh` deploys the files, starts a temporary local HTTP server, and attempts to open **tinybrowser** on the TV. On the TV, follow the on-screen instructions and move the bootstrap slider to **100%** to request manifest registration. The computer then independently invokes `scripts/verify.sh` to check whether the LS2 diagnostic executed with `uid=0(root)`.

You can also rerun the verification separately **after** manifest registration:

```bash
bash scripts/verify.sh
```

A successful diagnostic prints `SUCCESS: LS2 service executed as root.` If registration fails, the diagnostic produces no result, or root execution is not confirmed, do not treat the TV as rooted.

**Homebrew caveat:** `install.sh` also checks whether Homebrew Channel is installed. If it is missing, the script requires an independently authorized, executable `ROOT_RUNNER` to invoke the Homebrew installer; the LS2 diagnostic is **not** a general-purpose root command runner. Without that runner, the script exits at the Homebrew step even if the diagnostic succeeded. Do not assume that `install.sh` can install Homebrew from Developer Mode SSH alone.

### Troubleshooting

- **SSH fails:** Verify the TV IP, Developer Mode status, SSH port, authorized key, and `TV_HOST` setting. Test `ssh lg-tv 'id'` first. With `BatchMode yes`, a key or host-key problem fails instead of prompting.
- **Upload or checksum fails:** Verify that SSH can write to `/media/developer/temp/ls2root-v01/`, that `sha256sum` exists on the TV, and that `shasum` is installed on your computer.
- **tinybrowser does not open:** Confirm that the TV firmware provides `com.webos.app.tinybrowser` and that the launch request is supported.
- **Bootstrap page does not load:** Check `MAC_IP`, your computer's firewall settings, and whether TCP port `8765` is reachable from the TV.
- **No root result:** File deployment alone is insufficient. Complete manifest registration, then rerun `bash scripts/verify.sh`.
- **Homebrew missing / `ROOT_RUNNER` error:** This is a separate installation prerequisite, not proof that the LS2 diagnostic failed.

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
