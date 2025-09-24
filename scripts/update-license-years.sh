SPDX-License-Identifier: MIT
© 2023-2025 Kehd Emmanuel H. Diaz

#!/usr/bin/env bash
set -euo pipefail

# Calculate the current year
current_year="\$(date +'%Y')"

# 1. Bump the year range in LICENSE
sed -E "s/© 2023.*Diaz/© 2023–\$current_year Kehd Emmanuel H. Diaz/" 
LICENSE \
  | tee LICENSE.tmp >/dev/null && mv LICENSE.tmp LICENSE

# 2. Bump the year range in each .sh script (lines 1–2)
find . -type f -name '*.sh' | while IFS= read -r file; do
  sed -E '1,2 s/© 2023.*Diaz/© 2023–'"\$current_year"' Kehd Emmanuel H. 
Diaz/' "\$file" \
    | tee "\$file.tmp" >/dev/null && chmod --reference="\$file" "\$file.tmp" 
&& mv -f "\$file.tmp" "\$file"
done
