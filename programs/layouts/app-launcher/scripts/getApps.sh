#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir"/../app-data || exit 1

APP_DIRS=("/usr/share/applications" "${HOME}/.local/share/applications")
LIMIT=${1-0}
OFFSET=${2-0}

declare -a paths

printf '{\n\"apps\": [' 

limit_counter=0
offset_counter=0
stop=0

for dir in "${APP_DIRS[@]}"; do
  if [[ ${stop} -eq 1 ]]; then
    break
  fi

  for file in "${dir}"/*.desktop; do
    if [[ "${offset_counter}" -ne "${OFFSET}" ]]; then
      ((offset_counter += 1))
      continue
    fi

    if [[ "${limit_counter}" -eq "${LIMIT}" ]]; then
      stop=1
      break
    fi

    app_name="$(awk '/^\[Desktop Entry]/{f=1; next} /^\[/{f=0} f && !/]=/ && /^Name=/{sub(/^Name=/, ""); print; exit}' "${file}")"
    app_icon="$(awk '/^\[Desktop Entry]/{f=1; next} /^\[/{f=0} f && /^Icon=/{sub(/^Icon=/, ""); print; exit}' "${file}")"
    app_exec="$(awk '/^\[Desktop Entry]/{f=1; next} /^\[/{f=0} f && /^Exec=/{sub(/^Exec=/, ""); print; exit}' "${file}")"

    if [[ $app_name = "" || $app_exec = "" ]]; then
      continue
    fi

    if [[ -z "$app_icon" ]]; then
        app_icon_path="No-Icon"
    elif [[ "$app_icon" == /* ]]; then
        if [[ -f "$app_icon" ]]; then
            app_icon_path="$app_icon"
        else
            app_icon_path="No-Icon"
        fi
    else
        app_icon_path=$(find ~/.local/share/icons /usr/share/icons /usr/share/pixmaps -type f \
            \( -name "${app_icon}.png" -o -name "${app_icon}.svg" -o -name "${app_icon}.xpm" -o -name "${app_icon}" \) \
            2>/dev/null | head -n 1)
        
        if [[ -z "$app_icon_path" ]]; then
            app_icon_path="No-Icon"
        fi
    fi

    index="${#paths[@]}"
    paths["${index}"]="${file}"

    jq -n --arg name "${app_name}" \
      --arg icon "${app_icon_path}" \
      --arg path "${file}" \
      '{name: $name, icon: $icon, path: $path}' 

    if [[ $((limit_counter + 1)) -ne ${LIMIT} ]]; then
      echo ','
    fi

    ((limit_counter += 1))
  done
done

total="${#paths[@]}"

printf "\n],\n\"total\": %d\n}" "${total}" 
exit 0
