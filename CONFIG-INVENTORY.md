# 配置清单

| 配置 | 仓库路径 | 说明 |
| --- | --- | --- |
| Alacritty | `dotfiles/.config/alacritty/` | 主配置及其导入的 Tokyo Night 配色文件 |
| Starship | `dotfiles/.config/starship.toml` | 当前 Jetpack 外观配置 |
| Starship preset 备份 | `dotfiles/.config/starship-presets/tokyo-night.toml` | 本机原有 Tokyo Night 配置备份 |
| Neovim | `dotfiles/.config/nvim/` | `init.lua` 和 `lazy-lock.json` |
| tmux | `dotfiles/.tmux.conf` | tmux 配置 |
| Fcitx5 | `dotfiles/.config/fcitx5/` | 输入法配置和 profile |
| Flameshot | `dotfiles/.config/flameshot/flameshot.ini` | 截图工具配置 |
| GTK 3/4 | `dotfiles/.config/gtk-3.0/`、`dotfiles/.config/gtk-4.0/` | GTK 外观设置 |
| GNOME 扩展状态 | `gnome/enabled-extensions.txt` | 已启用扩展 ID |
| GNOME 扩展设置 | `gnome/extensions.dconf` | `/org/gnome/shell/extensions/` 导出 |
| GNOME 界面设置 | `gnome/interface.dconf` | `/org/gnome/desktop/interface/` 导出 |
| GNOME 视觉资源 | `assets/gnome-visuals.tar.zst` | WhiteSur 主题、图标主题及 Bibata 光标；解压恢复到家目录 |
| Bash 环境 | `dotfiles/.bashrc`、`dotfiles/.bash_profile`、`dotfiles/.profile` | Shell 初始化、ble.sh、Starship、nvm 和环境变量 |

本机另检测到 nvm 0.40.4、Node.js v24.21.0、pnpm 10.34.6、uv 0.12.23，以及 `~/.local/share/blesh/ble.sh`。这些工具本体没有放进仓库。软件清单见 `packages/`。没有保留浏览器配置目录、Codex 私有状态、下载的 Neovim 插件缓存，也没有把应用程序二进制文件放进仓库。
