#!/bin/bash
set -e

# TRACE localization generation.
#
# NOTE: This was Mercury's script that downloaded a Google Sheet CSV
# (Mercury-specific) and generated Localizable.strings via the GenerateStrings
# binary. TRACE does not yet have its own localization sheet, so to keep the
# build hermetic (no network dependency, no Mercury content) this step is a
# no-op for now. The committed Localizable.strings under
# Projects/UIComponent/Resources/Localization/ are the source of truth and are
# consumed directly by SwiftGen.
#
# To re-enable sheet-based generation later, restore the download + GenerateStrings
# invocation and point SHEET_URL at the TRACE localization sheet.

echo "[INFO] Localization: using committed Localizable.strings (sheet sync disabled for TRACE)."
echo "[✅] Done!"
