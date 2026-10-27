#!/bin/zsh
set -eu
cd "${0:A:h:h}"
mkdir -p .build/modules
swiftc -module-cache-path "$PWD/.build/modules" Sources/PlustagMonitor/Usage.swift Sources/PlustagMonitor/WidgetSnapshot.swift scripts/Check.swift -o .build/PlustagCheck
.build/PlustagCheck "$@"
