#!/bin/sh
fail=0
if wget -q -T 5 -O /dev/null http://1.1.1.1 2>/dev/null; then
  echo "reach 1.1.1.1        OPEN"
  fail=1
else
  echo "reach 1.1.1.1        blocked"
fi
if wget -q -T 5 -O /dev/null http://example.com 2>/dev/null; then
  echo "reach example.com    OPEN"
  fail=1
else
  echo "reach example.com    blocked"
fi
exit "$fail"
