#!/usr/bin/env python3
"""Export train/trained_autoencoder.mat (v7.3) to JSON for Flutter/WPF runtimes."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import h5py
import numpy as np

REPO = Path(__file__).resolve().parents[1]
MAT = (
    REPO.parent
    / "Karavi.Thesis.AudioSignalStealthLogisticChaosMapping"
    / "train"
    / "trained_autoencoder.mat"
)
OUT_FLUTTER = REPO / "src/audio_stegano_app/assets/stego/trained_autoencoder.json"
OUT_CORE = (
    REPO / "src/audio_stegano_desktop/src/AudioStegano.Core/Stego/trained_autoencoder.json"
)


def tansig(n: np.ndarray) -> np.ndarray:
    return 2.0 / (1.0 + np.exp(-2.0 * np.clip(n, -500, 500))) - 1.0


def main() -> int:
    if not MAT.is_file():
        print(f"Missing {MAT}", file=sys.stderr)
        return 1

    with h5py.File(MAT, "r") as f:
        # MATLAB stores IW/LW transposed in HDF5; use net cell refs (10×8, 8×10).
        iw = np.array(f[f["net/IW"][0, 0]]).T
        lw = np.array(f[f["net/LW"][0, 1]]).T
        b1 = np.array(f[f["net/b"][0, 0]]).ravel()
        b2 = np.array(f[f["net/b"][0, 1]]).ravel()

    export = {
        "architecture": "8-10-8",
        "transfer": "tansig",
        "inputSize": 8,
        "hiddenSize": 10,
        "outputSize": 8,
        "iw": iw.tolist(),
        "lw": lw.tolist(),
        "b1": b1.tolist(),
        "b2": b2.tolist(),
    }

    for out in (OUT_FLUTTER, OUT_CORE):
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(export, separators=(",", ":")), encoding="utf-8")
        print(f"Wrote {out} ({out.stat().st_size} bytes)")

    # Sanity: forward one column
    x = np.array([1, 0, 1, 0, 1, 0, 1, 0], dtype=float)
    n1 = iw @ x + b1
    y = lw @ tansig(n1) + b2
    print("sample out", np.round(tansig(y), 4))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
