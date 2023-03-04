#!/usr/bin/env bash

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
ROOT_DIR=$(cd -- "$SCRIPT_DIR"/.. && pwd)

PRODUCTION=false
if [ "$1" == "--production" ]; then
    PRODUCTION=true
fi

rm -f "${ROOT_DIR}"/hugo/layouts/partials/critical-css.html
echo "<style>" >> "${ROOT_DIR}"/hugo/layouts/partials/critical-css.html
cat "${ROOT_DIR}"/hugo/build/index.html | critical --base "${ROOT_DIR}"/hugo/build >> "${ROOT_DIR}"/hugo/layouts/partials/critical-css.html
echo "</style>" >> "${ROOT_DIR}"/hugo/layouts/partials/critical-css.html

if [ "$PRODUCTION" = true ]; then
    if [ "$(uname)" == "Darwin" ]; then
        sed -i '' 's/preprod-asim.ihsan.io/asim.ihsan.io/g' "${ROOT_DIR}"/hugo/layouts/partials/critical-css.html
    else
        sed -i 's/preprod-asim.ihsan.io/asim.ihsan.io/g' "${ROOT_DIR}"/hugo/layouts/partials/critical-css.html
    fi
fi