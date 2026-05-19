#!/bin/bash

LIMIT=300
FAILED=0

echo "Checking Dart files over ${LIMIT} lines..."
echo ""

find lib -name "*.dart" | while read file; do
  lines=$(wc -l < "$file" | tr -d ' ')
  if [ "$lines" -gt "$LIMIT" ]; then
    echo "WARNING: $file has $lines lines"
    echo "Solution: split into widgets/services/helpers so each file stays under $LIMIT lines"
    echo ""
    FAILED=1
  fi
done
