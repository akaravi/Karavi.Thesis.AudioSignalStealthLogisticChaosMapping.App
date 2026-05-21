# Workflows

## `release-on-publish-tag.yml`

| Trigger | When it runs |
|---------|----------------|
| `workflow_dispatch` | Always (if self-hosted runner is **Online**) |
| Push tag `publish`, `publish/**`, `publish-*` | Only if repo variable `SELF_HOSTED_RUNNER_READY` = `true` |

### Setup (once)

```powershell
.\scripts\ci\Setup-GitHubSelfHostedRunner.ps1
cd .github-runner
.\config.cmd --url https://github.com/OWNER/REPO --token TOKEN_FROM_GITHUB
.\run.cmd
```

```powershell
.\scripts\ci\Enable-ReleaseWorkflowRepository.ps1 -SetVariable
```

### Billing

Do **not** use `windows-latest` (GitHub-hosted). This workflow uses **self-hosted** only.

### Without runner

```powershell
.\_publish-local-github-release.ps1 -TagName publish/1.0.0+1
```
