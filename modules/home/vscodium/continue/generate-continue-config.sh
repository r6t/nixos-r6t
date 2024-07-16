#!/usr/bin/env bash

OPENAI_KEY=$(cat /run/secrets/openai/platform_key)

# Generate the final config.json
cat <<EOF > /home/r6t/.continue/config.json
{
  "models": [
    {
      "model": "gpt-4-turbo-preview",
      "title": "GPT-4 Turbo Paid",
      "apiBase": "https://api.openai.com/v1/",
      "provider": "openai",
      "apiKey": "$OPENAI_KEY"
    },
    {
      "title": "Ollama",
      "provider": "ollama",
      "model": "AUTODETECT",
      "completionOptions": {}
    }
  ],
  "tabAutocompleteModel": {
      "title": "Tab Autocomplete Model",
      "provider": "ollama",
      "model": "deepseek-coder-v2:latest",
      "apiBase": "http://127.0.0.1:11434"
  },
  "slashCommands": [
    {
      "name": "edit",
      "description": "Edit selected code"
    },
    {
      "name": "comment",
      "description": "Write comments for the selected code"
    },
    {
      "name": "share",
      "description": "Download and share this session"
    },
    {
      "name": "cmd",
      "description": "Generate a shell command"
    }
  ],
  "customCommands": [
    {
      "name": "test",
      "prompt": "Write a comprehensive set of unit tests for the selected code. It should setup, run tests that check for correctness including important edge cases, and teardown. Ensure that the tests are complete and sophisticated. Give the tests just as chat output, don't edit any file.",
      "description": "Write unit tests for highlighted code"
    }
  ],
  "contextProviders": [
    {
      "name": "diff",
      "params": {}
    },
    {
      "name": "open",
      "params": {}
    },
    {
      "name": "terminal",
      "params": {}
    },
    {
      "name": "problems",
      "params": {}
    },
    {
      "name": "codebase",
      "params": {}
    },
    {
      "name": "code",
      "params": {}
    },
    {
      "name": "docs",
      "params": {}
    }
  ],
  "allowAnonymousTelemetry": false
}
EOF