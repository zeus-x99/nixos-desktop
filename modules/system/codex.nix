{ lib, pkgs, userSettings, ... }:
let
  mkUserActivation = import ../../lib/mk-user-activation.nix {
    inherit lib userSettings;
  };

  tomlFormat = pkgs.formats.toml { };

  defaultInstructions = ''
    - 默认使用简体中文回复；保持简洁、可执行。
    - 在运行命令前先用一行概述要做的事，并成组说明相关步骤；危险/破坏性操作务必先征求确认。
    - 大型/多阶段任务使用计划步骤并逐步更新进度。
    - 引用文件请用 `path:line` 形式；避免过度格式化。
    - 在代码库中遵循项目的 AGENTS.md 与既有代码风格；只做最小必要改动。
    - `/etc/nixos` 仓库内的配置文件通常由 `root` 拥有；需要修改这类文件时，默认直接使用 `sudo` 编辑或写入，不要先尝试无权限写入再回退。
    - Nix/NixOS 变更优先 `nix flake check` 与 `sudo nixos-rebuild dry-activate --flake .#...`；高风险再用 `test`，确认无误后再 `switch`。
  '';

  codexIntroPrompt = pkgs.writeText "codex-intro.md" ''
    ---
    description: 项目快速介绍与基础导航
    ---
    请基于当前工作目录，输出一份简明的项目介绍。包含：
    - 项目概要：目标/领域、主要技术栈、关键目录结构
    - 构建与运行：常用命令（测试、构建、启动），必要的环境依赖
    - 配置与约定：主要配置文件、代码风格/格式化、命名约定
    - 风险与注意：容易踩坑点、敏感操作前的确认步骤
    - 若侦测到 Nix/flake.nix：附上 `nix flake check`、`sudo nixos-rebuild dry-activate/test/switch --flake .#<host>` 的用法说明

    输出格式：
    - 先给出 2-3 句摘要
    - 再以要点列表分组呈现，尽量给出可直接复制执行的命令
  '';

  codexReviewPrompt = pkgs.writeText "codex-review.md" ''
    ---
    description: 针对指定文件/范围进行代码审查并给出可执行建议
    argument-hint: FILE=<path> [FOCUS=<section>]
    ---
    请审查文件 $FILE 。如果提供了 FOCUS，请重点关注 $FOCUS 。

    要求：
    - 指出潜在问题（正确性、健壮性、安全性、性能、可维护性）
    - 给出可执行的修复建议与示例片段
    - 使用 `path:line` 形式引用定位
    - 保持简洁分点，必要时给出最小可行改动（避免过度重构）
  '';

  codexConfig = tomlFormat.generate "codex-config.toml" {
    model_provider = "packycode";
    model = "gpt-5.5";
    model_reasoning_effort = "xhigh";
    web_search = "live";
    disable_response_storage = true;
    developer_instructions = defaultInstructions;
    model_providers.packycode = {
      name = "packycode";
      base_url = "https://cpa.imagic.wiki/v1";
      wire_api = "responses";
      requires_openai_auth = true;
      env_key = "CLIPROXYAPI_API_KEY";
    };
    projects = {
      "/etc/nixos" = {
        trust_level = "trusted";
        sandbox_mode = "workspace-write";
        network_access = "enabled";
        approval_policy = "on-request";
      };
      "${userSettings.home}/nixos" = {
        trust_level = "trusted";
        sandbox_mode = "workspace-write";
        network_access = "enabled";
        approval_policy = "on-request";
      };
      "${userSettings.home}" = {
        trust_level = "trusted";
      };
    };
    mcp_servers.openaiDeveloperDocs = {
      url = "https://developers.openai.com/mcp";
    };
  };

in
{
  systemd.tmpfiles.rules = [
    "L+ /usr/bin/bwrap - - - - /run/current-system/sw/bin/bwrap"
  ];
} // mkUserActivation {
  name = "zeusCodexFiles";
  dryMessage = "would install ${userSettings.name} codex files";
  files = [
    {
      source = codexConfig;
      target = ".codex/config.toml";
    }
    {
      source = codexIntroPrompt;
      target = ".codex/prompts/intro.md";
    }
    {
      source = codexReviewPrompt;
      target = ".codex/prompts/review.md";
    }
  ];
}
