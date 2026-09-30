#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

# Renders config.yaml, this app's nginx config, and the admin UI's static
# files (if enabled) to match the current $webui setting. Shared between
# install, upgrade, and scripts/config's set__webui, so toggling webui
# later goes through the exact same logic as the original install did,
# rather than a second hand-kept copy of it.
#
# Assumes $app/$domain/$install_dir (settings, always available) and
# $webui ("0" or "1") are already set, and CWD is this package's
# scripts/ directory (true for install/upgrade/config/remove -- not
# backup/restore, which never call this).
tsbridge_apply_webui() {
    if [ "$webui" -eq 1 ]; then
        management_socket="/run/$app/control.sock"
        management_socket_mode="0660"
        management_socket_group="www-data"
    else
        management_socket=""
        management_socket_mode=""
        management_socket_group=""
    fi

    ynh_config_add --template="config.yaml" --destination="$install_dir/config.yaml"
    chmod 640 "$install_dir/config.yaml"
    chown "$app:$app" "$install_dir/config.yaml"

    if [ "$webui" -eq 1 ]; then
        # 711, not install_dir's own (more restrictive) default: lets
        # www-data (nginx) traverse into the one subdirectory meant to be
        # served -- www/ -- by exact path, without being able to list
        # $install_dir itself or read config.yaml/tsbridge.env's content;
        # those stay protected by their own 640/600 regardless of this.
        chmod 711 "$install_dir"
        mkdir -p "$install_dir/www"
        cp -r ../sources/www/. "$install_dir/www/"
        chown -R "$app:$app" "$install_dir/www"
        find "$install_dir/www" -type d -exec chmod 755 {} +
        find "$install_dir/www" -type f -exec chmod 644 {} +
        ynh_config_add --template="nginx-webui.conf" --destination="/etc/nginx/conf.d/$domain.d/$app.conf"
    else
        ynh_safe_rm "$install_dir/www"
        chmod 750 "$install_dir"
        ynh_config_add --template="nginx-disabled.conf" --destination="/etc/nginx/conf.d/$domain.d/$app.conf"
    fi

    ynh_systemctl --service=nginx --action=reload
}
