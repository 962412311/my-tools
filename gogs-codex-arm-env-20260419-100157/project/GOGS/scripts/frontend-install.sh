#!/bin/bash

set -euo pipefail

node "$(dirname "$0")/frontend-tool.js" install
