#!/usr/bin/env fish
for var in BEDROCK_KEYS GH_TOKEN
  if test -r /run/secrets/$var
    set -x $var (cat /run/secrets/$var)
  end
end

