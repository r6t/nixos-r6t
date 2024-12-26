#!/usr/bin/env bash
# Generate the final config.json
cat <<EOF > /home/r6t/.continue/config.json
{
  "models": [
    {
      "model": "AUTODETECT",
      "title": "Ollama",
      "apiBase": "http://hedgehog.magic.internal:11434",
      "provider": "ollama"
    }
  ],
  "tabAutocompleteModel": {
      "title": "Tab Autocomplete Model",
      "provider": "ollama",
      "model": "qwen2.5-coder:14b",
      "apiBase": "http://hedgehog.magic.internal:11434"
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
      "name": "tree",
      "params": {}
    },
    {
      "name": "folder",
      "params": {}
    },
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
