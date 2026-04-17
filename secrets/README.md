# sops-nix

当前仓库已接入 `sops-nix`，但默认不会要求你立刻提交密文文件。

建议流程：

1. 先取本机 SSH host key 对应的 age recipient：

```bash
sudo ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

2. 基于它创建 `secrets/.sops.yaml`：

```yaml
creation_rules:
  - path_regex: secrets/[^/]+\\.yaml$
    key_groups:
      - age:
          - age1replace_me
```

3. 创建密文文件：

```bash
sops secrets/secrets.yaml
chmod 0644 secrets/secrets.yaml
```

`secrets/secrets.yaml` 是加密后的密文文件，可以保持仓库内可读；这样普通用户执行 `nix flake check` 时不会因为本地 flake 需要读取源文件而报 `Permission denied`。

建议至少放入以下键：

```yaml
cliproxyapi_api_key: your-key
```

创建后，这个值会被渲染到 `/run/secrets/rendered/codex-api.env`，Nushell 会直接读取它。
