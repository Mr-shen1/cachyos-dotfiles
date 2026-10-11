#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="${HOME:?HOME is not set}"
BACKUP_DIR="$HOME_DIR/.local/state/cachyos-dotfiles-backups/$(date +%Y%m%d-%H%M%S)-$$"
BACKUP_CREATED=false
TEMP_DIRS=()

log() {
    printf '[setup] %s\n' "$*"
}

warn() {
    printf '[setup] 警告：%s\n' "$*" >&2
}

fail() {
    printf '[setup] 错误：%s\n' "$*" >&2
    exit 1
}

cleanup() {
    local dir
    for dir in "${TEMP_DIRS[@]}"; do
        rm -rf -- "$dir"
    done
}
trap cleanup EXIT

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "缺少命令：$1"
}

read_manifest() {
    local file="$1"
    local array_name="$2"
    local line
    local -n result="$array_name"

    [[ -f "$file" ]] || fail "找不到清单：$file"
    result=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line//[[:space:]]/}"
        [[ -z "$line" ]] || result+=("$line")
    done < "$file"
}

install_packages() {
    local -a pacman_packages aur_packages
    read_manifest "$REPO_DIR/packages/pacman-explicit.txt" pacman_packages
    read_manifest "$REPO_DIR/packages/aur-explicit.txt" aur_packages

    if command -v cachyos-rate-mirrors >/dev/null 2>&1; then
        log "更新 CachyOS 和 Arch 镜像列表。"
        sudo cachyos-rate-mirrors
    else
        warn "找不到 cachyos-rate-mirrors，使用当前镜像列表继续。"
    fi

    if ((${#pacman_packages[@]})); then
        log "安装 pacman 清单中的软件。"
        sudo pacman -Syu --needed -- "${pacman_packages[@]}"
    fi

    if ((${#aur_packages[@]})); then
        command -v paru >/dev/null 2>&1 || fail "AUR 清单需要 paru；请先安装 paru 后重试。"
        log "安装 AUR 清单中的软件。"
        paru -S --needed -- "${aur_packages[@]}"
    fi
}

install_manual_tools() {
    local nvm_dir="$HOME_DIR/.nvm"
    local blesh_path="$HOME_DIR/.local/share/blesh/ble.sh"
    local temp_dir

    require_command curl

    if [[ ! -s "$nvm_dir/nvm.sh" ]]; then
        log "安装 nvm 0.40.4。"
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    fi
    [[ -s "$nvm_dir/nvm.sh" ]] || fail "nvm 安装后未找到 $nvm_dir/nvm.sh"

    export NVM_DIR="$nvm_dir"
    # shellcheck disable=SC1090
    . "$NVM_DIR/nvm.sh"
    nvm install --lts

    if ! command -v pnpm >/dev/null 2>&1; then
        command -v npm >/dev/null 2>&1 || fail "安装 pnpm 前找不到 npm；请检查 nvm 和 Node.js。"
        log "通过 npm 安装 pnpm 10 系列最新版本。"
        npm install -g pnpm@latest-10
    fi

    if ! command -v uv >/dev/null 2>&1; then
        log "安装 uv。"
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    if [[ -f "$HOME_DIR/.local/bin/env" ]]; then
        # shellcheck disable=SC1091
        . "$HOME_DIR/.local/bin/env"
    fi
    command -v uv >/dev/null 2>&1 || fail "uv 安装后仍不可用。"

    if [[ ! -r "$blesh_path" ]]; then
        require_command tar
        temp_dir="$(mktemp -d)"
        TEMP_DIRS+=("$temp_dir")
        log "安装 ble.sh nightly。"
        curl -L --fail --silent --show-error \
            https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz \
            | tar -xJf - -C "$temp_dir"
        [[ -r "$temp_dir/ble-nightly/ble.sh" ]] || fail "ble.sh 压缩包内容不符合预期。"
        bash "$temp_dir/ble-nightly/ble.sh" --install "$HOME_DIR/.local/share"
    fi
}

backup_destination() {
    local destination="$1"
    local relative_path="$2"
    local backup_path="$BACKUP_DIR/$relative_path"

    mkdir -p "$(dirname -- "$backup_path")"
    mv -- "$destination" "$backup_path"
    BACKUP_CREATED=true
}

install_file() {
    local source="$1"
    local relative_path="$2"
    local destination="$HOME_DIR/$relative_path"

    if [[ -L "$source" ]]; then
        if [[ -L "$destination" ]] && [[ "$(readlink -- "$source")" == "$(readlink -- "$destination")" ]]; then
            return
        fi
    elif [[ -f "$destination" && ! -L "$destination" ]] && cmp -s -- "$source" "$destination"; then
        return
    fi

    if [[ -e "$destination" || -L "$destination" ]]; then
        backup_destination "$destination" "$relative_path"
    fi

    mkdir -p "$(dirname -- "$destination")"
    cp -a -- "$source" "$destination"
}

deploy_tree() {
    local tree_root="$1"
    local source relative_path

    while IFS= read -r -d '' source; do
        relative_path="${source#"$tree_root"/}"
        install_file "$source" "$relative_path"
    done < <(find "$tree_root" \( -type f -o -type l \) -print0)
}

restore_dotfiles() {
    log "部署配置文件；现有同名文件会先备份到 $BACKUP_DIR。"
    deploy_tree "$REPO_DIR/dotfiles"

    if [[ -f "$REPO_DIR/assets/gnome-visuals.tar.zst" ]]; then
        require_command tar
        local temp_dir
        temp_dir="$(mktemp -d)"
        TEMP_DIRS+=("$temp_dir")
        log "解压 GNOME 主题、图标和光标资源。"
        tar --zstd -xf "$REPO_DIR/assets/gnome-visuals.tar.zst" -C "$temp_dir"
        [[ -d "$temp_dir/dotfiles" ]] || fail "主题压缩包中未找到 dotfiles/ 目录。"
        deploy_tree "$temp_dir/dotfiles"
    else
        warn "没有找到 GNOME 视觉资源压缩包，跳过主题、图标和光标恢复。"
    fi

    if [[ "$BACKUP_CREATED" == true ]]; then
        log "原有文件已备份到：$BACKUP_DIR"
    else
        log "没有需要备份的同名配置文件。"
    fi
}

install_tmux_theme() {
    local plugin_dir="$HOME_DIR/.config/tmux/plugins/catppuccin"
    local plugin_file="$plugin_dir/tmux/catppuccin.tmux"

    [[ -f "$plugin_file" ]] && return
    if [[ -e "$plugin_dir" ]]; then
        warn "Catppuccin tmux 插件目录已存在但缺少入口文件：$plugin_file"
        return
    fi
    if ! command -v git >/dev/null 2>&1; then
        warn "找不到 git，未能下载 tmux 配置所需的 Catppuccin 插件。"
        return
    fi

    mkdir -p "$(dirname -- "$plugin_dir")"
    log "下载 tmux 配置引用的 Catppuccin 插件。"
    if ! git clone --depth 1 https://github.com/catppuccin/tmux.git "$plugin_dir"; then
        warn "Catppuccin tmux 插件下载失败；其他初始化步骤继续。"
    fi
}

restore_gnome_settings() {
    if ! command -v dconf >/dev/null 2>&1; then
        warn "找不到 dconf，跳过 GNOME 设置恢复。"
        return
    fi

    log "恢复 GNOME 扩展和界面设置。"
    if ! dconf load /org/gnome/shell/extensions/ < "$REPO_DIR/gnome/extensions.dconf"; then
        warn "GNOME 扩展设置未能写入；请在 GNOME 会话中重新运行对应的 dconf load 命令。"
    fi
    if ! dconf load /org/gnome/desktop/interface/ < "$REPO_DIR/gnome/interface.dconf"; then
        warn "GNOME 界面设置未能写入；请在 GNOME 会话中重新运行对应的 dconf load 命令。"
    fi

    if ! command -v gnome-extensions >/dev/null 2>&1; then
        warn "找不到 gnome-extensions，跳过扩展启用。"
        return
    fi
    local installed_extensions extension
    if ! installed_extensions="$(gnome-extensions list 2>/dev/null)"; then
        warn "无法连接 GNOME Shell；扩展启用步骤已跳过。"
        return
    fi

    while IFS= read -r extension || [[ -n "$extension" ]]; do
        [[ -z "$extension" ]] && continue
        if grep -Fqx -- "$extension" <<< "$installed_extensions"; then
            if ! gnome-extensions enable "$extension"; then
                warn "扩展启用失败：$extension"
            fi
        else
            warn "扩展尚未安装，未能启用：$extension"
        fi
    done < "$REPO_DIR/gnome/enabled-extensions.txt"
}

main() {
    [[ "$EUID" -ne 0 ]] || fail "请以普通用户运行；安装 pacman 软件时脚本会调用 sudo。"
    require_command pacman
    require_command sudo

    install_packages
    install_manual_tools
    restore_dotfiles
    install_tmux_theme
    restore_gnome_settings

    log "初始化完成。GNOME 扩展代码未打包；上面的提示会列出尚未安装、因此无法启用的扩展。"
}

main "$@"
