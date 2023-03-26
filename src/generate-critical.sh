#!/usr/bin/env bash

set -euo pipefail

# This script generates critical CSS for the website. It will write the critical CSS to the file
# `hugo/layouts/partials/critical-css.html`. This file is then included in the head of the website.
#
# Usage:
#   ./generate-critical.sh [--production]
#
# The `--production` flag will replace the preprod URL with the production URL in the generated CSS.

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
ROOT_DIR=$(cd -- "$SCRIPT_DIR"/.. && pwd)

PRODUCTION=false

while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        --production)
            PRODUCTION=true
            shift
            ;;
        *)
            echo "Unknown option: $key"
            exit 1
            ;;
    esac
done

rm -f "${ROOT_DIR}"/hugo/layouts/partials/critical-css.html
echo "<style>" >> "${ROOT_DIR}"/hugo/layouts/partials/critical-css.html
node "${SCRIPT_DIR}/get-css/get-css.js" >> "${ROOT_DIR}"/hugo/layouts/partials/critical-css.html
echo "</style>" >> "${ROOT_DIR}"/hugo/layouts/partials/critical-css.html

if [ "$PRODUCTION" = true ]; then
    if [ "$(uname)" == "Darwin" ]; then
        sed -i '' 's/preprod-asim.ihsan.io/asim.ihsan.io/g' "${ROOT_DIR}"/hugo/layouts/partials/critical-css.html
    else
        sed -i 's/preprod-asim.ihsan.io/asim.ihsan.io/g' "${ROOT_DIR}"/hugo/layouts/partials/critical-css.html
    fi
fi
