#!/usr/bin/env python3
"""
FLAC Audio Quality Analyzer

Scans a directory of FLAC files, detects likely upsampled or lossy-sourced files
"""

import argparse
import concurrent.futures
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Tuple


@dataclass
class AnalysisResult:
    """Holds the results of FLAC file analysis."""

    file: Path
    sample_rate: int
    bit_depth: int
    max_freq: float
    nyquist: float


def get_metadata(file: Path) -> Tuple[Optional[int], Optional[int]]:
    """Extract sample rate and bit depth using metaflac."""
    try:
        sr = int(
            subprocess.check_output(
                ["metaflac", "--show-sample-rate", str(file)], text=True
            ).strip()
        )
        bd = int(
            subprocess.check_output(
                ["metaflac", "--show-bits-per-sample", str(file)], text=True
            ).strip()
        )
        return sr, bd
    except (subprocess.CalledProcessError, ValueError) as err:
        print(f"Metadata error for {file}: {err}")
        return None, None


def analyze_frequency(file: Path) -> float:
    """Use SoX to determine the maximum frequency present in the file."""
    try:
        proc = subprocess.run(
            ["sox", str(file), "-n", "stat", "-freq"],
            capture_output=True,
            text=True,
            check=True,
        )
        # sox outputs frequency info to stderr
        freqs = []
        for line in proc.stderr.splitlines():
            if line and not line.startswith(";"):
                try:
                    freq, _ = line.split()
                    freqs.append(float(freq))
                except ValueError:
                    continue
        return max(freqs) if freqs else 0.0
    except subprocess.CalledProcessError as err:
        print(f"Frequency analysis failed for {file}: {err}")
        return 0.0


def analyze_file(file: Path) -> Optional[AnalysisResult]:
    """Analyze a single FLAC file for upsampling artifacts."""
    sample_rate, bit_depth = get_metadata(file)
    if not sample_rate:
        return None
    nyquist = sample_rate / 2
    max_freq = analyze_frequency(file)
    return AnalysisResult(file, sample_rate, bit_depth, max_freq, nyquist)


def main() -> None:
    """Main entry point for the analyzer."""
    parser = argparse.ArgumentParser(
        description="Analyze FLAC files for upsampling artifacts."
    )
    parser.add_argument("directory", type=Path, help="Directory containing FLAC files")
    parser.add_argument(
        "--threshold", type=float, default=16000, help="Frequency threshold (Hz)"
    )
    parser.add_argument("--workers", type=int, default=4, help="Parallel workers")
    args = parser.parse_args()

    flacs: List[Path] = list(args.directory.rglob("*.flac"))
    print(f"Found {len(flacs)} FLAC files.")

    suspects: List[AnalysisResult] = []
    with concurrent.futures.ProcessPoolExecutor(max_workers=args.workers) as pool:
        for result in pool.map(analyze_file, flacs):
            if result and (
                result.max_freq < args.threshold
                or result.max_freq < result.nyquist * 0.9
            ):
                suspects.append(result)

    print(f"\nPotential upsampled or lossy files ({len(suspects)}):")
    for res in suspects:
        print(
            f"{res.file}\n  Sample Rate: {res.sample_rate} Hz, Bit Depth: {res.bit_depth}-bit"
        )
        print(f"  Nyquist: {res.nyquist:.1f} Hz, Max Freq: {res.max_freq:.1f} Hz\n")

    with open("audio_quality_report.txt", "w", encoding="utf-8") as report_file:
        for res in suspects:
            report_file.write(
                f"{res.file}\n  Sample Rate: {res.sample_rate} Hz, Bit Depth: {res.bit_depth}-bit\n"
            )
            report_file.write(
                f"  Nyquist: {res.nyquist:.1f} Hz, Max Freq: {res.max_freq:.1f} Hz\n\n"
            )


if __name__ == "__main__":
    main()
