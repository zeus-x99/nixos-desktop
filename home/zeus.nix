{
  lib,
  pkgs,
  userSettings,
  ...
}:
let
  q = lib.escapeShellArg;

  defaultInstructions = ''
    - 默认使用简体中文回复；保持简洁、可执行。
    - 在运行命令前先用一行概述要做的事，并成组说明相关步骤；危险/破坏性操作务必先征求确认。
    - 大型/多阶段任务使用计划步骤并逐步更新进度。
    - 引用文件请用 `path:line` 形式；避免过度格式化。
    - 在代码库中遵循项目的 AGENTS.md 与既有代码风格；只做最小必要改动。
    - `/etc/nixos` 仓库内的配置文件通常由 `root` 拥有；需要修改这类文件时，默认直接使用 `sudo` 编辑或写入，不要先尝试无权限写入再回退。
    - Nix/NixOS 变更优先 `nix flake check` 与 `sudo nixos-rebuild dry-activate --flake .#...`；高风险再用 `test`，确认无误后再 `switch`。
  '';

  codexIntroPrompt = ''
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

  codexReviewPrompt = ''
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

  wallpaperImage = ../assets/wallpapers/sunlight-beams-wallpaper-3840x2160-magical-woods-forest-magic-29641.jpg;
  wallpaperPath = toString wallpaperImage;

  noctaliaSettingsSeed = pkgs.writeText "zeus-noctalia-settings.json" (
    builtins.toJSON {
      general = {
        enableBlurBehind = true;
        showChangelogOnStartup = false;
      };
      ui = {
        panelBackgroundOpacity = 0.45;
        translucentWidgets = true;
      };
      bar = {
        barType = "floating";
        position = "top";
        backgroundOpacity = 0.45;
        useSeparateOpacity = false;
        showCapsule = true;
        capsuleOpacity = 0.45;
        marginVertical = 6;
        marginHorizontal = 6;
        frameThickness = 8;
        frameRadius = 14;
        widgetSpacing = 6;
        contentPadding = 2;
        widgets = {
          left = [
            { id = "Workspace"; }
            { id = "ActiveWindow"; }
          ];
          center = [
            {
              id = "Clock";
              clockColor = "none";
              useCustomFont = false;
              customFont = "";
              formatHorizontal = "HH:mm ddd, MMM dd";
              formatVertical = "HH mm - dd MM";
              tooltipFormat = "HH:mm ddd, MMM dd";
            }
            { id = "MediaMini"; }
          ];
          right = [
            {
              id = "Tray";
              drawerEnabled = false;
              hidePassive = true;
            }
            {
              id = "SystemMonitor";
              compactMode = false;
              useMonospaceFont = true;
              usePadding = true;
              showCpuUsage = true;
              showCpuCores = false;
              showCpuFreq = false;
              showCpuTemp = false;
              showGpuTemp = false;
              showLoadAverage = false;
              showMemoryUsage = true;
              showMemoryAsPercent = true;
              showSwapUsage = false;
              showNetworkStats = true;
              showDiskUsage = false;
              showDiskUsageAsPercent = false;
              showDiskAvailable = false;
              diskPath = "/";
            }
            { id = "NotificationHistory"; }
            { id = "Volume"; }
            { id = "ControlCenter"; }
          ];
        };
      };
      dock = {
        enabled = false;
        backgroundOpacity = 0.45;
      };
      location = {
        name = "Chengdu";
        autoLocate = false;
        weatherEnabled = true;
        useFahrenheit = false;
        use12hourFormat = false;
        firstDayOfWeek = -1;
      };
      colorSchemes = {
        darkMode = false;
        schedulingMode = "location";
        manualSunrise = "06:30";
        manualSunset = "18:30";
        syncGsettings = true;
        useWallpaperColors = true;
        predefinedScheme = "One";
        generationMethod = "tonal-spot";
        monitorForColors = "HDMI-A-1";
      };
      controlCenter = {
        cards = [
          {
            enabled = true;
            id = "profile-card";
          }
          {
            enabled = true;
            id = "shortcuts-card";
          }
          {
            enabled = true;
            id = "audio-card";
          }
          {
            enabled = false;
            id = "brightness-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
          {
            enabled = true;
            id = "media-sysmon-card";
          }
        ];
        shortcuts = {
          left = [
            { id = "Network"; }
            { id = "Bluetooth"; }
            { id = "WallpaperSelector"; }
            { id = "PowerProfile"; }
          ];
          right = [
            { id = "Notifications"; }
            { id = "KeepAwake"; }
            { id = "DarkMode"; }
            { id = "NightLight"; }
          ];
        };
      };
      osd = {
        enabled = true;
        location = "top_right";
        autoHideMs = 1400;
        overlayLayer = true;
        backgroundOpacity = 0.45;
        enabledTypes = [
          0
          1
          2
        ];
        monitors = [ ];
      };
      notifications = {
        backgroundOpacity = 0.45;
      };
      wallpaper = {
        enabled = true;
        directory = builtins.dirOf wallpaperPath;
        viewMode = "single";
        setWallpaperOnAllMonitors = true;
        linkLightAndDarkWallpapers = true;
        fillMode = "crop";
        useSolidColor = false;
        overviewEnabled = true;
        overviewBlur = 0.4;
        overviewTint = 0.45;
      };
    }
  );

  noctaliaWallpaperCacheSeed = pkgs.writeText "zeus-noctalia-wallpapers.json" (
    builtins.toJSON {
      wallpapers = { };
      defaultWallpaper = wallpaperPath;
      usedRandomWallpapers = { };
    }
  );

  narakaAppId = "1203220";
  narakaLaunchOptions = "PROTON_FORCE_NVAPI=1 PROTON_HIDE_NVIDIA_GPU=0 DXVK_FILTER_DEVICE_NAME='NVIDIA GeForce RTX 5070' VK_DRIVER_FILES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json gamemoderun %command%";
  steamLaunchOptionsUpdater = pkgs.writeText "steam-launch-options-updater.pl" ''
    use strict;
    use warnings;

    my ($path) = @ARGV;
    my $app_id = $ENV{STEAM_APP_ID} // die "STEAM_APP_ID is required\n";
    my $launch_options = $ENV{STEAM_LAUNCH_OPTIONS} // die "STEAM_LAUNCH_OPTIONS is required\n";

    sub vdf_quote {
      my ($value) = @_;
      $value =~ s/\\/\\\\/g;
      $value =~ s/"/\\"/g;
      return qq{"$value"};
    }

    sub matching_brace {
      my ($text, $open) = @_;
      my $depth = 0;
      my $in_string = 0;
      my $escaped = 0;
      my $length = length($text);

      for (my $i = $open; $i < $length; $i++) {
        my $char = substr($text, $i, 1);

        if ($in_string) {
          if ($escaped) {
            $escaped = 0;
          } elsif ($char eq '\\') {
            $escaped = 1;
          } elsif ($char eq '"') {
            $in_string = 0;
          }
          next;
        }

        if ($char eq '"') {
          $in_string = 1;
        } elsif ($char eq '{') {
          $depth++;
        } elsif ($char eq '}') {
          $depth--;
          return $i if $depth == 0;
        }
      }

      return undef;
    }

    sub named_block {
      my ($text, $key, $from, $until) = @_;
      $from //= 0;
      $until //= length($text);
      my $needle = vdf_quote($key);
      my $pos = $from;

      while (($pos = index($text, $needle, $pos)) >= 0 && $pos < $until) {
        my $after_key = $pos + length($needle);
        if (substr($text, $after_key, $until - $after_key) =~ /\G\s*\{/gc) {
          my $open = $after_key + $+[0] - 1;
          my $close = matching_brace($text, $open);
          return ($open, $close) if defined($close) && $close <= $until;
        }
        $pos = $after_key;
      }

      return;
    }

    sub last_named_block {
      my ($text, $key) = @_;
      my $from = 0;
      my @last;

      while (my @block = named_block($text, $key, $from)) {
        @last = @block;
        $from = $block[1] + 1;
      }

      return @last;
    }

    open my $in, '<', $path or die "open $path: $!\n";
    local $/;
    my $text = <$in>;
    close $in;

    my $quoted_options = vdf_quote($launch_options);
    my ($apps_open, $apps_close) = last_named_block($text, 'apps');

    if (!defined($apps_open)) {
      my $apps_block = qq{\t"apps"\n\t{\n\t\t"$app_id"\n\t\t{\n\t\t\t"LaunchOptions"\t\t$quoted_options\n\t\t}\n\t}\n};
      $text =~ s/\n\}\s*$/\n$apps_block}/s or die "failed to add apps block to $path\n";
    } else {
      my ($app_open, $app_close) = named_block($text, $app_id, $apps_open + 1, $apps_close);

      if (!defined($app_open)) {
        substr($text, $apps_close, 0) = qq{\t\t"$app_id"\n\t\t{\n\t\t\t"LaunchOptions"\t\t$quoted_options\n\t\t}\n};
      } else {
        my $app_body_start = $app_open + 1;
        my $app_body = substr($text, $app_body_start, $app_close - $app_body_start);

        if ($app_body =~ s/^([ \t]*)"LaunchOptions"\s*"(?:\\.|[^"])*"/$1"LaunchOptions"\t\t$quoted_options/m) {
          substr($text, $app_body_start, $app_close - $app_body_start) = $app_body;
        } else {
          substr($text, $app_close, 0) = qq{\t\t\t"LaunchOptions"\t\t$quoted_options\n};
        }
      }
    }

    open my $out, '>', $path or die "write $path: $!\n";
    print {$out} $text;
    close $out;
  '';
in
{
  home = {
    username = userSettings.name;
    homeDirectory = userSettings.home;
    stateVersion = "25.11";
  };

  xdg = {
    enable = true;
    dataFile."fcitx5/rime/default.custom.yaml".text = ''
      patch:
        schema_list:
          - schema: rime_ice
        menu/page_size: 9
        "ascii_composer/switch_key/Shift_L": commit_code
    '';
  };

  programs.home-manager.enable = true;

  programs.nushell = {
    enable = true;
    package = null;
    settings = {
      show_banner = false;
      edit_mode = "vi";
    };
    shellAliases = {
      dev = "nix develop /etc/nixos#default -c nu -l";
      shx = "sudo -E hx";
    };
    envFile.text = ''
      $env.EDITOR = "${pkgs.helix}/bin/hx"

      let codex_env_file = "/run/secrets/rendered/codex-api.env"

      if ($codex_env_file | path exists) {
        for line in (open $codex_env_file | lines) {
          if ($line | str starts-with "OPENAI_API_KEY=") {
            $env.OPENAI_API_KEY = ($line | str replace "OPENAI_API_KEY=" "")
          }
        }
      }

      let codex_auth_file = $"($env.HOME)/.codex/auth.json"
      if ($codex_auth_file | path exists) {
        $env.OPENAI_API_KEY = (open $codex_auth_file | get OPENAI_API_KEY | str trim)
      }
    '';
    loginFile.text = "";
  };

  programs.starship = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      follow_symlinks = false;
    };
  };

  programs.helix = {
    enable = true;
    settings = {
      theme = "darcula";
      editor = {
        line-number = "relative";
        mouse = false;
        auto-info = true;
        lsp.display-messages = true;
        lsp.auto-signature-help = true;
        lsp.display-inlay-hints = true;
        lsp.display-signature-help-docs = true;
        inline-diagnostics = {
          cursor-line = "hint";
          other-lines = "error";
        };
        statusline = {
          left = [
            "mode"
            "spinner"
          ];
          center = [ "file-name" ];
          right = [
            "diagnostics"
            "selections"
            "position"
            "file-encoding"
            "file-line-ending"
            "file-type"
          ];
        };
        gutters = [
          "diagnostics"
          "spacer"
          "line-numbers"
          "spacer"
          "diff"
        ];
        soft-wrap.enable = true;
        completion-replace = true;
        auto-save = true;
      };
      keys.normal.space = {
        w = ":write";
        q = ":quit";
        x = ":write-quit";
      };
    };
    languages = {
      language-server.nil.command = "${pkgs.nil}/bin/nil";
      language = [
        {
          name = "nix";
          auto-format = true;
          formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
          language-servers = [ "nil" ];
        }
        {
          name = "python";
          auto-format = true;
          formatter = {
            command = "ruff";
            args = [
              "format"
              "--stdin-filename"
              "%{buffer_name}"
              "-"
            ];
          };
        }
        {
          name = "rust";
          auto-format = true;
          formatter = {
            command = "rustfmt";
            args = [ "--emit=stdout" ];
          };
        }
      ];
    };
  };

  programs.codex = {
    enable = true;
    package = null;
    settings = {
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
        env_key = "OPENAI_API_KEY";
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
  };

  home.file = {
    ".codex/prompts/intro.md".text = codexIntroPrompt;
    ".codex/prompts/review.md".text = codexReviewPrompt;
  };

  home.activation = {
    cleanupMigratedUserFiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      ${pkgs.coreutils}/bin/rm -rf \
        "$HOME/.cache/starship/init.nu" \
        "$HOME/.config/niri/config.kdl" \
        "$HOME/.config/fcitx5/config" \
        "$HOME/.config/fcitx5/profile" \
        "$HOME/.config/fcitx5/conf/classicui.conf" \
        "$HOME/.config/fcitx5/conf/pinyin.conf" \
        "$HOME/.local/share/fcitx5/pinyin" \
        "$HOME/.cache/DankMaterialShell" \
        "$HOME/.config/DankMaterialShell" \
        "$HOME/.config/niri/dms" \
        "$HOME/.local/state/DankMaterialShell" \
        "$HOME/.config/MangoHud/MangoHud.conf" \
        "$HOME/.local/state/MangoHud"
    '';

    noctaliaFiles = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      ${pkgs.coreutils}/bin/install -D -m 0644 \
        ${q (toString noctaliaSettingsSeed)} \
        "$HOME/.config/noctalia/settings.json"

      if [ ! -e "$HOME/.cache/noctalia/wallpapers.json" ]; then
        ${pkgs.coreutils}/bin/install -D -m 0644 \
          ${q (toString noctaliaWallpaperCacheSeed)} \
          "$HOME/.cache/noctalia/wallpapers.json"
      fi
    '';

    steamLaunchOptions = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      seen_configs=""
      for steam_config in \
        "$HOME"/.local/share/Steam/userdata/*/config/localconfig.vdf \
        "$HOME"/.steam/steam/userdata/*/config/localconfig.vdf; do
        if [ ! -e "$steam_config" ]; then
          continue
        fi

        real_config="$(${pkgs.coreutils}/bin/readlink -f "$steam_config")"
        case " $seen_configs " in
          *" $real_config "*) continue ;;
        esac
        seen_configs="$seen_configs $real_config"

        STEAM_APP_ID=${q narakaAppId} \
        STEAM_LAUNCH_OPTIONS=${q narakaLaunchOptions} \
          ${pkgs.perl}/bin/perl ${q (toString steamLaunchOptionsUpdater)} "$real_config"
      done
    '';
  };
}
