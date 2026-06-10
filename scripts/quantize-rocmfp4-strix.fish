#!/usr/bin/env fish
#
# Quantize a Qwen3.6-35B-A3B-MTP BF16 source GGUF to one of the ROCmFP4 STRIX
# profiles using the llama-quantize binary from this flake's rocmfp4-llama
# package.
#
# This is a one-time setup step per goldenball, not a regular runtime task.
# Run it once per profile you want to use; the resulting GGUF is referenced
# from hosts/goldenball/llm-config.nix via the `modelFile` option.
#
# Pipeline:
#   1. Build the rocmfp4-llama package via nix (no-op if already in /nix/store)
#   2. Download the BF16 source GGUF from ggml-org/Qwen3.6-35B-A3B-MTP-GGUF
#      (~71 GB, ~10-20 min on a fast connection). Skipped if already cached.
#   3. Run llama-quantize with the requested ROCmFP4 STRIX profile
#      (~30-60 min wall-clock, CPU-bound).
#   4. Move the result to /var/cache/llama-cpp/local-quants/.
#   5. Optionally delete the BF16 source to free 71 GB.
#
# Usage:
#   ./scripts/quantize-rocmfp4-strix.fish --profile lean
#   ./scripts/quantize-rocmfp4-strix.fish --profile strix --keep-bf16
#   ./scripts/quantize-rocmfp4-strix.fish --profile lean --bf16-path /path/to/bf16.gguf
#
# Recovery: if a previous run was interrupted mid-quantize, just re-run.
# llama-quantize starts from scratch but the BF16 download is resumed.

set -l profile lean
set -l keep_bf16 0
set -l bf16_path ""

# ── parse args ────────────────────────────────────────────────────────────
set -l i 1
while test $i -le (count $argv)
    set -l a $argv[$i]
    switch $a
        case --profile
            set i (math $i + 1)
            set profile $argv[$i]
        case --keep-bf16
            set keep_bf16 1
        case --bf16-path
            set i (math $i + 1)
            set bf16_path $argv[$i]
        case -h --help
            echo "Usage: "(status filename)" [--profile lean|strix] [--keep-bf16] [--bf16-path PATH]"
            exit 0
        case '*'
            echo "Unknown argument: $a" >&2
            exit 1
    end
    set i (math $i + 1)
end

if not contains $profile lean strix
    echo "Error: --profile must be one of: lean, strix (got '$profile')" >&2
    exit 1
end

# ── paths ────────────────────────────────────────────────────────────────
set -l flake_root (realpath (dirname (status filename))/..)
set -l hf_repo "ggml-org/Qwen3.6-35B-A3B-MTP-GGUF"
set -l hf_file "Qwen3.6-35B-A3B-MTP-BF16.gguf"
set -l hf_url "https://huggingface.co/$hf_repo/resolve/main/$hf_file"
# /var/lib/llama-cpp-models is provisioned by goldenball's tmpfiles (r6t:users
# 0755) so this script can write without sudo. Do NOT use /var/cache/llama-cpp
# here — that's systemd's CacheDirectory under DynamicUser, mode 0700, dynamic
# UID; r6t can't traverse it.
set -l work_dir "/var/lib/llama-cpp-models"
set -l bf16_default "$work_dir/$hf_file"

if test -z "$bf16_path"
    set bf16_path "$bf16_default"
end

set -l quant_type
set -l output_name
switch $profile
    case lean
        set quant_type "Q4_0_ROCMFP4_STRIX_LEAN"
        set output_name "Qwen3.6-35B-A3B-MTP-ROCmFP4-STRIX_LEAN.gguf"
    case strix
        set quant_type "Q4_0_ROCMFP4_STRIX"
        set output_name "Qwen3.6-35B-A3B-MTP-ROCmFP4-STRIX.gguf"
end
set -l output_path "$work_dir/$output_name"

echo "──────────────────────────────────────────────────────────────"
echo "  Profile:       $profile ($quant_type)"
echo "  Source BF16:   $bf16_path"
echo "  Output GGUF:   $output_path"
echo "  Keep BF16:     "(if test $keep_bf16 -eq 1; echo "yes"; else; echo "no (will delete)"; end)
echo "──────────────────────────────────────────────────────────────"

# ── ensure the work dir exists with right ownership ──────────────────────
if not test -d "$work_dir"
    echo ">> Creating $work_dir (requires sudo)"
    if not sudo mkdir -p "$work_dir"
        echo "Error: failed to create $work_dir. Run this once manually:" >&2
        echo "    sudo mkdir -p $work_dir" >&2
        echo "    sudo chown -R $USER:"(id -gn)" $work_dir" >&2
        exit 1
    end
end

# Always normalize ownership: prior runs may have left the dir owned by root
# (e.g. an earlier version of this script that hardcoded $USER:$USER).
set -l user_group (id -gn)
if not test -w "$work_dir"
    echo ">> Fixing $work_dir ownership to $USER:$user_group (requires sudo)"
    if not sudo chown -R "$USER:$user_group" "$work_dir"
        echo "Error: failed to chown $work_dir. Run this once manually:" >&2
        echo "    sudo chown -R $USER:$user_group $work_dir" >&2
        exit 1
    end
end

# Final guard: if we still can't write, bail before the confusing curl error.
if not test -w "$work_dir"
    echo "Error: $work_dir is not writable by $USER even after attempted chown." >&2
    echo "Run this once manually, then re-run the script:" >&2
    echo "    sudo chown -R $USER:$user_group $work_dir" >&2
    exit 1
end

# ── 1. build rocmfp4-llama ───────────────────────────────────────────────
echo ">> Building flake package #rocmfp4-llama (cached if already built)..."
if not nix build --print-out-paths "$flake_root#rocmfp4-llama" >/tmp/rocmfp4-out-path
    echo "Error: nix build failed" >&2
    exit 1
end
set -l rocmfp4_bin (cat /tmp/rocmfp4-out-path)/bin
echo ">> Binaries at: $rocmfp4_bin"

if not test -x "$rocmfp4_bin/llama-quantize"
    echo "Error: llama-quantize not found at $rocmfp4_bin/llama-quantize" >&2
    exit 1
end

# ── 2. download BF16 source if missing ───────────────────────────────────
if test -f "$bf16_path"
    set -l existing_size (stat -c %s "$bf16_path" 2>/dev/null)
    # The real BF16 is ~71 GB. Anything under 1 GB is a partial/corrupt
    # download (e.g. an HTML error page from HF). Wipe it so curl -C -
    # doesn't try to resume from a bogus offset.
    if test $existing_size -lt 1073741824
        echo ">> Existing $bf16_path is only $existing_size bytes (expected ~71 GB);"
        echo "   treating as corrupt partial and removing."
        rm -f "$bf16_path"
    else
        echo ">> BF16 source already present ($existing_size bytes), resuming/skipping download."
    end
end

if not test -f "$bf16_path"
    echo ">> Downloading BF16 source (71 GB) — this may take 10-30 min..."
    # curl -C - resumes partial downloads. -L follows redirects (HF uses S3).
    if not curl -L --fail --retry 3 --retry-delay 5 -C - -o "$bf16_path" "$hf_url"
        echo "Error: BF16 download failed" >&2
        exit 1
    end
    echo ">> Download complete."
end

# ── 3. quantize ──────────────────────────────────────────────────────────
echo ""
echo ">> Quantizing BF16 → $quant_type (~30-60 min, CPU-bound)..."
echo ""
# llama-quantize signature: llama-quantize <input> <output> <type>
if not "$rocmfp4_bin/llama-quantize" "$bf16_path" "$output_path" "$quant_type"
    echo "Error: quantization failed" >&2
    exit 1
end

set -l output_size (stat -c %s "$output_path" 2>/dev/null)
echo ""
echo "──────────────────────────────────────────────────────────────"
echo "  Done. Output: $output_path"
echo "  Size:        "(math "$output_size / 1024 / 1024 / 1024")" GiB"
echo "──────────────────────────────────────────────────────────────"

# ── 4. cleanup ───────────────────────────────────────────────────────────
if test $keep_bf16 -eq 0
    echo ">> Deleting BF16 source ($bf16_path) to free ~71 GB"
    rm -f "$bf16_path"
end

echo ""
echo "Next: set hosts/goldenball/llm-config.nix activeModel to the matching"
echo "preset (qwen3-6-35b-a3b-rocmfp4-$profile) and rebuild:"
echo ""
echo "    sudo nixos-rebuild switch --flake .#goldenball"
echo "    systemctl restart llama-cpp"
