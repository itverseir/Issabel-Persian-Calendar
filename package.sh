#!/bin/bash
# ==============================================================================
# Issabel PBX - Persian Calendar Package Builder
# Developed by: Amir Safari - ITVERSE.IR
# Copyright (c) 2024-2026 Amir Safari - ITVERSE.IR. All rights reserved.
# مالکیت مادی و معنوی: امیر صفری - ITVERSE.IR
# ==============================================================================

set -e

VERSION="1.1.0"
PACKAGE_NAME="issabel-persian-calendar-v${VERSION}.tar.gz"

echo "Building package: $PACKAGE_NAME ..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure executable permissions on shell scripts
chmod +x install.sh uninstall.sh package.sh 2>/dev/null || true

# Create tar.gz excluding temporary files, git, and backups
tar -czvf "$PACKAGE_NAME" \
    --exclude="*.bak*" \
    --exclude=".git*" \
    --exclude="*.tar.gz" \
    --exclude="verify_dates.js" \
    install.sh \
    uninstall.sh \
    package.sh \
    README.md \
    README_FA.md \
    test_dates.php \
    LICENSE \
    modules/

echo "Package created successfully: $PACKAGE_NAME"
ls -lh "$PACKAGE_NAME"
