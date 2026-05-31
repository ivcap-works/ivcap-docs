# Install the CLI

The `ivcap` CLI is the primary way to interact with an IVCAP deployment from the
command line — discovering services, submitting jobs, managing artifacts, and more.

---

## Install

=== "macOS / Linux (Homebrew)"

    ```bash
    brew tap ivcap-works/ivcap
    brew install ivcap
    ```

=== "macOS / Linux (binary)"

    Download the latest pre-built binary from the
    [releases page](https://github.com/ivcap-works/ivcap-cli/releases/latest),
    make it executable, and place it somewhere on your `PATH`:

    ```bash
    # Example for macOS arm64 — adjust the filename for your platform
    curl -L https://github.com/ivcap-works/ivcap-cli/releases/latest/download/ivcap-Darwin-arm64 \
         -o /usr/local/bin/ivcap
    chmod +x /usr/local/bin/ivcap
    ```

=== "Windows (PowerShell)"

    ```powershell
    Invoke-WebRequest `
      -Uri https://github.com/ivcap-works/ivcap-cli/releases/latest/download/ivcap-Windows-amd64.exe `
      -OutFile ivcap.exe
    Move-Item ivcap.exe 'C:\Program Files\ivcap\ivcap.exe'
    # Add C:\Program Files\ivcap to your PATH if it is not already there
    ```

Verify the installation:

```bash
ivcap --version
```

!!! tip "Build from source"
    If you need the very latest development build, see the
    [ivcap-cli repository](https://github.com/ivcap-works/ivcap-cli) for
    build-from-source instructions.

---

## Configure a context

A **context** tells the CLI which IVCAP deployment to talk to and stores your
credentials. You can maintain multiple contexts and switch between them freely.

### Create a context

Replace `<deployment-url>` with the base URL of your IVCAP deployment (ask your
platform administrator if you are unsure):

```bash
ivcap context create my-deployment https://<deployment-url>
```

### List contexts

```bash
ivcap context list
+---------+----------------+-----------------------------+------------------------------+
| CURRENT | NAME           | ACCOUNTID                   | URL                          |
+---------+----------------+-----------------------------+------------------------------+
| *       | my-deployment  | urn:ivcap:account:4c65b865  | https://<deployment-url>     |
+---------+----------------+-----------------------------+------------------------------+
```

### Switch between contexts

```bash
ivcap context set my-deployment
```

---

## Log in

Most operations require an authorisation token. Run:

```bash
ivcap context login
```

A QR code and a URL will appear in your terminal. Open the URL (or scan the QR
code) and follow the prompts in your browser. Once authenticated the CLI will
store the token automatically.

```
    █▀▀▀▀▀█    ▀█  ▄▀▄▀▀ ▄▄▀▄ █▀▀▀▀▀█
    █ ███ █ █  █▀ ▀█▀ █  ▀▀█  █ ███ █
    ...
To login to the IVCAP Service, please go to:
  https://id-provider.com/activate?user_code=....
or scan the QR Code to be taken to the login page
Waiting for authorisation...
```

Verify you are authenticated:

```bash
ivcap context get
+-------------+----------------------------------+
| Name        | my-deployment                    |
| URL         | https://<deployment-url>         |
| Account ID  | urn:ivcap:account:45a06508-...   |
| Authorised  | yes, refreshing after ...        |
+-------------+----------------------------------+
```

---

## Available commands

```
ivcap
  artifact    Create and manage artifacts
  collection  Create and manage collections
  context     Manage and set access to IVCAP deployments
  datafabric  Query the datafabric; create and manage aspects
  job         Create and manage jobs
  mcp         Start a local MCP server exposing IVCAP tools
  package     Push/pull and manage service packages
  queue       Create and manage queues
  secret      Set and list secrets
  service     Create and manage services
```

For full documentation of every command and flag see the
[ivcap-cli repository](https://github.com/ivcap-works/ivcap-cli).

---

## Next steps

With the CLI installed and authenticated you are ready to run your first analysis:

[→ Run Your First Analysis](run-analysis.md){ .md-button .md-button--primary }
