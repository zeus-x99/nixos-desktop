# Repository Guidelines

## 项目结构与模块组织
- `configuration.nix` 为系统主入口，`hardware-configuration.nix` 保存硬件检测配置。
- `flake.nix` 定义 `nixosConfigurations.nixos`，`flake.lock` 锁定输入版本。
- `modules/system/` 放置系统级模块（如 `host.nix`、`network.nix`、`packages.nix`）。
- `modules/services/` 放置服务模块与默认汇总（如 `desktop.nix`、`openssh.nix`、`default.nix`）。
- `lib/import-modules.nix` 用于自动导入模块目录中的 `.nix` 文件。

## 构建、测试与开发命令
- `nix flake check`：基础检查与评估，改动前后都建议运行。
- `sudo nixos-rebuild dry-activate --flake .#nixos`：生成并验证配置，不实际切换。
- `sudo nixos-rebuild test --flake .#nixos`：临时切换用于验证；确认无误后再用 `switch`。
- `sudo nixos-rebuild switch --flake .#nixos`：正式切换到新配置。

## 编码风格与命名约定
- Nix 文件使用 2 空格缩进，属性集与列表按现有风格排版。
- 文件名保持小写与职责清晰（如 `host.nix`、`packages.nix`、`desktop.nix`）。
- 注释简短、说明“为什么”，避免重复代码含义。

## 测试指南
- 当前无专用测试框架；以 `nix flake check` 与 `nixos-rebuild dry-activate` 作为基本验证。
- 涉及服务变更时，建议在目标主机上补充 `systemctl status <service>` 等运行态检查。

## 安全与配置提示
- 敏感信息优先放到独立密钥文件或环境文件，不要直接写进 Nix 仓库。
- 当前 Codex API key 由 `sops-nix` 渲染到 `/run/secrets/rendered/codex-api.env`；不要把明文密钥写进 Nix 仓库。
- 当目标文件需要 root 权限时，可直接使用 `sudo` 进行编辑或写入；仍需保持最小必要改动，并避免未经确认的破坏性操作。
