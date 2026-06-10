# ROCmFP4 llama.cpp fork for AMD Strix Halo (gfx1151).
#
# Builds charlie12345/rocmfp4-llama (mtp-rocmfp4-strix branch), a research fork
# of llama.cpp that adds:
#   - Q4_0_ROCMFP4 / Q4_0_ROCMFP4_FAST quant types (custom 4-bit weight formats)
#   - ROCmFP4 STRIX / STRIX_LEAN tensor-aware presets
#   - HIP/ROCm + Vulkan kernel paths for the new quants
#   - Reported 89-104 tok/s decode on Qwen3.6-35B-A3B-MTP at 262K context
#
# Builds both HIP and Vulkan backends in one binary so runtime can fall back
# to Vulkan via `-dev Vulkan0` if HIP misbehaves.
#
# WebUI is disabled (LLAMA_BUILD_WEBUI=OFF) — clients connect via OpenAI API
# only, no need for the bundled webui (avoids npm fetchNpmDeps overhead).
#
# Status: experimental research build. Numbers are hardware/driver/model/prompt
# sensitive. Not upstream. Pinned to a specific commit for reproducibility;
# update `rev` and `hash` to track the branch.
{ lib
, stdenv
, cmake
, ninja
, pkg-config
, fetchFromGitHub
, rocmPackages
, shaderc
, vulkan-headers
, vulkan-loader
, spirv-headers
, openssl
, installShellFiles
,
}:

let
  inherit (lib) cmakeBool cmakeFeature;
in
stdenv.mkDerivation {
  pname = "rocmfp4-llama";
  version = "mtp-rocmfp4-strix-2026-06-05";

  outputs = [
    "out"
    "dev"
  ];

  src = fetchFromGitHub {
    owner = "charlie12345";
    repo = "rocmfp4-llama";
    # Branch: mtp-rocmfp4-strix; pinned to a specific commit for reproducibility.
    # Update `rev` + `hash` together. To get a new hash:
    #   nix-prefetch-github charlie12345 rocmfp4-llama --rev <COMMIT>
    rev = "1faa48eefdf1a0eda238e5cde7f69c951eb1a9e9";
    hash = "sha256-twAnRmTzTOACgTpOTOoWErobgxBnhwniKfJzhY8RLHg=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    spirv-headers
    installShellFiles
  ];

  buildInputs = [
    # ROCm / HIP runtime + BLAS (matches nixpkgs llama-cpp-rocm closure)
    rocmPackages.clr
    rocmPackages.hipblas
    rocmPackages.rocblas
    # Vulkan compiler + headers + loader for the second backend
    shaderc
    vulkan-headers
    vulkan-loader
    # Server HTTPS support
    openssl
  ];

  cmakeFlags = [
    # Build hygiene
    (cmakeBool "GGML_NATIVE" false)
    (cmakeBool "BUILD_SHARED_LIBS" true)
    (cmakeBool "LLAMA_BUILD_EXAMPLES" false)
    (cmakeBool "LLAMA_BUILD_SERVER" true)
    (cmakeBool "LLAMA_BUILD_TESTS" false)
    # WebUI disabled: keeps closure small, no npm dep needed
    (cmakeBool "LLAMA_BUILD_WEBUI" false)
    (cmakeBool "LLAMA_USE_PREBUILT_WEBUI" false)
    (cmakeBool "LLAMA_OPENSSL" true)

    # Backends — mirror the fork's build-strix-rocmfp4-mtp.sh script
    (cmakeBool "GGML_HIP" true)
    (cmakeBool "GGML_HIP_FORCE_MMQ" true) # critical for ROCmFP4 kernel path
    (cmakeBool "GGML_HIP_ROCWMMA_FATTN" false) # would need rocWMMA headers
    (cmakeBool "GGML_VULKAN" true) # dual-backend build
    (cmakeBool "GGML_CUDA" false)
    (cmakeBool "GGML_BLAS" false)
    (cmakeBool "GGML_METAL" false)
    (cmakeBool "GGML_RPC" false)

    # Single-target build for goldenball — gfx1151 only.
    # Override via .override { rocmGpuTargets = [ "gfx1151" "gfx1150" ]; }
    # if other Strix Halo machines are added later.
    (cmakeFeature "CMAKE_HIP_COMPILER" "${rocmPackages.clr.hipClangPath}/clang++")
    (cmakeFeature "CMAKE_HIP_ARCHITECTURES" "gfx1151")
  ];

  # Build only the binaries we actually need. The fork's script also builds
  # several test-* binaries; skip them here (LLAMA_BUILD_TESTS=false above
  # already excludes them).
  ninjaFlags = [
    "llama-cli"
    "llama-server"
    "llama-completion"
    "llama-quantize"
    "llama-bench"
  ];

  postInstall = ''
    # Match nixpkgs convention: provide a `llama` shim alongside `llama-cli`.
    ln -sf $out/bin/llama-cli $out/bin/llama

    # Headers for downstream consumers (matches nixpkgs llama-cpp output layout).
    mkdir -p $out/include
    cp $src/include/llama.h $out/include/
  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd llama-server --bash <($out/bin/llama-server --completion-bash)
  '';

  doCheck = false;

  meta = {
    description = "ROCmFP4-quantized llama.cpp fork for AMD Strix Halo (gfx1151)";
    homepage = "https://github.com/charlie12345/rocmfp4-llama";
    license = lib.licenses.mit;
    mainProgram = "llama-server";
    platforms = [ "x86_64-linux" ];
  };
}
