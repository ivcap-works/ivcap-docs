
# IVCAP CLI Tool

The `ivcap` CLI tool provides a convenient way to interaction with an IVCAP deployment from the command line

## Installation

The `ivcap` CLI tool here are ready to use binaries for some architectures available at the [repo's release](https://github.com/ivcap-works/ivcap-cli/releases/latest) tab.

If you use homebrew, you can install it by:

```
brew tap brew tap ivcap-works/ivcap
brew install ivcap
```

Please verify at this point that you can successfully log into the IVCAP cluster of your choice. See the [Configure context for a specific deployment](https://github.com/ivcap-works/ivcap-cli?tab=readme-ov-file#configure-context-for-a-specific-deployment) section in the _ivcap-cli_ repo.

```
% ivcap context get
+-------------+--------------------------------+
| Name        | gke-dev                        |
| URL         | https://develop.ivcap.net      |
| Account ID  | urn:ivcap:account:45a06508...  |
| Authorised  | yes, refreshing after ...      |
+-------------+--------------------------------+
```


## Usage¶

Here is a quick overview of the most useful ivcap command line interface (CLI) commands.
```
  artifact    Create and manage artifacts
  aspect      Create and manage aspects
  collection  Create and manage collections
  order       Create and manage orders
  service     Create and manage services

  context     Manage and set access to IVCAP deployments
  help        Help about any command
```

See the [CLI repo](https://github.com/ivcap-works/ivcap-cli/blob/main/README.md) for more details.