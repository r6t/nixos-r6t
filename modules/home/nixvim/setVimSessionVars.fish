#!/usr/bin/env fish
# Load AWS Bedrock credentials (CSV format: access-key-id,secret-access-key,region)
if test -r /run/secrets/BEDROCK_KEYS
  set -l creds (cat /run/secrets/BEDROCK_KEYS)
  set -l parts (string split ',' $creds)
  
  set -gx AWS_ACCESS_KEY_ID $parts[1]
  set -gx AWS_SECRET_ACCESS_KEY $parts[2]
  set -gx AWS_REGION $parts[3]
end

# Load OpenRouter API key
if test -r /run/secrets/OPENROUTER_API_KEY
  set -gx OPENROUTER_API_KEY (string trim (cat /run/secrets/OPENROUTER_API_KEY))
end
