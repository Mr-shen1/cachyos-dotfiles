# CachyOS 配置与软件清单

这里整理的是目前关注的软件清单和对应配置快照，方便后续迁移时查阅。软件本体不存入仓库；主题资源等配置依赖除外。

## 内容

- `packages/pacman-explicit.txt`：筛选后的 pacman 软件清单，共 19 行。
- `packages/aur-explicit.txt`：筛选后的 AUR 清单，共 3 行。
- `dotfiles/`：按家目录相对路径组织的配置文件。
- `assets/gnome-visuals.tar.zst`：GNOME 主题、图标、光标资源压缩包。
- `gnome/`：GNOME 扩展启用状态、扩展设置和桌面界面设置导出。

## 初始化

在 CachyOS/Arch Linux 新机器上，将仓库放到本地后运行：

```bash
bash ./install.sh
```

脚本会先运行 `sudo cachyos-rate-mirrors` 更新镜像列表，再用 `pacman -Syu` 完整升级系统并安装 pacman 清单，之后安装 AUR 清单；接着按下文方式安装 nvm、Node.js LTS、pnpm、uv 和 ble.sh，部署配置文件，并恢复主题、图标、光标及 GNOME dconf 设置。完整系统升级可能需要较长时间，且升级后可能需要重启。替换已有配置前会把原文件备份到 `~/.local/state/cachyos-dotfiles-backups/`。tmux 配置引用的 Catppuccin 插件会从上游仓库下载。

如果目标机没有 `cachyos-rate-mirrors`（例如普通 Arch Linux），脚本会提示并沿用当前镜像列表；CachyOS 官方建议镜像异常时重排镜像并执行 `pacman -Syu`。[CachyOS 故障排查文档](https://wiki.cachyos.org/cachyos_basic/faq/)。

GNOME 扩展代码本身没有存入仓库。脚本只会启用目标机器上已经安装的扩展；未安装的扩展会显示提示，需要先通过 Extension Manager 等方式安装。

## 当前整理的配置

- Alacritty：`dotfiles/.config/alacritty/`，主配置引用仓库内的 Tokyo Night 配色文件。
- Starship：`dotfiles/.config/starship.toml` 是当前配置；内容对应内置 Jetpack preset。`starship-presets/tokyo-night.toml` 保存了本机的 Tokyo Night 备份。
- Neovim、tmux、Fcitx5、Flameshot：配置位于 `dotfiles/.config/` 和 `dotfiles/.tmux.conf`。
- GNOME：`gnome/*.dconf` 保存设置；`assets/gnome-visuals.tar.zst` 包含 WhiteSur 主题、图标和 Bibata 光标资源。展开后约 223 MB，压缩包约 12 MB。
- Shell：保留了 `.bashrc`、`.bash_profile` 和 `.profile`；`.bashrc` 包含 ble.sh、Starship 和 nvm 初始化。

本机当前界面选择为 GTK 主题 `WhiteSur-Dark`、图标主题 `WhiteSur-dark`、光标主题 `Bibata-Modern-Ice`，并启用深色外观。主题资源压缩包包含对应主题、图标和光标文件。

在仓库根目录运行以下命令，可将主题资源恢复到家目录：

```bash
tar --zstd -xf assets/gnome-visuals.tar.zst --strip-components=1 -C "$HOME"
```

## 本机检测到的手动安装工具

这些工具不是 pacman/AUR 清单中的包：

- ble.sh：`~/.local/share/blesh/ble.sh` 存在，当前家目录 `.bashrc` 会加载它。
- nvm：`0.40.4`；当前 Node.js：`v24.21.0`；pnpm：`10.34.6`。
- uv：`0.12.23`。

`dotfiles/.bashrc` 会在 ble.sh 文件存在时加载它，并包含 Starship 和 nvm 初始化。

## nvm、pnpm、uv 和 ble.sh

`install.sh` 会按以下方式安装 nvm、pnpm 和 uv；如果要手工安装，也可以逐段执行。nvm 安装后会安装当时最新的 Node.js LTS 版。

### Node.js：nvm

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
source ~/.bashrc
nvm install --lts
node -v
```

`nvm install --lts` 安装当时最新的 LTS 版 Node.js，因此之后安装出来的版本可能与本机当前的 `v24.21.0` 不同。

### pnpm

```bash
npm install -g pnpm@latest-10
pnpm -v
```

`latest-10` 表示安装 pnpm 10 系列中当时的最新版本；本机当前版本是 `10.34.6`。

### uv

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source $HOME/.local/bin/env
uv
```

安装脚本未指定版本，会安装其默认版本。本机当前是 `uv 0.12.23`。截图里的 `uv` 用于启动并显示命令帮助；检查具体版本可运行 `uv --version`。

ble.sh 会从 nightly 压缩包安装到 `~/.local/share/blesh/`；`.bashrc` 仅在文件存在时加载它。

## GNOME 扩展包名

清单使用本机实际安装的包名 `gnome-shell-extension-appindicator`，它提供 AppIndicator/KStatusNotifierItem 托盘图标支持。Arch 另有 `gnome-shell-extensions`（复数）包，内容是 GNOME 项目维护的一组扩展；`gnome-shell-extension`（单数）不是这两个包的别名。

目标机器仍需先安装清单中的 GNOME 扩展；脚本只恢复设置并启用已安装的扩展。

## 排除项

未收录浏览器用户数据、登录状态、缓存、Codex 会话数据等机器专属或敏感内容。Node.js、pnpm、uv 和 ble.sh 使用上游安装脚本或发行包动态安装，不在仓库中保存软件本体。
