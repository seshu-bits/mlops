# ==========================
# Team Information
# ==========================
# Group No 39
# Team Members:
# 1. Akilan K. S. L., 2024AB05003
# 2. Nagendra Prasad Reddy K. V. S., 2024aa05960
# 3. Piramanayagam P., 2024AB05015
# 4. Prathyusha Devi K., 2024aa05182
# 5. Sai Venkata Naga Sesh Kumar Ghanta., 2024aa05989
# ==========================

#!/usr/bin/env python3
"""
Generate scaler files for existing models in artifacts/ directory.
This ensures reproducibility for already-trained models.
"""

import pickle
from pathlib import Path

from MLOps_Assignment import (
    clean_and_preprocess_heart_data,
    load_raw_heart_data,
    prepare_ml_features,
)


def main():
    print("Generating scaler files for existing models...")
    print("=" * 60)

    # Load and preprocess data to get the scaler
    data_dir = Path("./data")
    artifacts_dir = Path("./artifacts")

    print("\n1. Loading and preprocessing data...")
    raw_df = load_raw_heart_data(data_dir=data_dir)
    cleaned_df = clean_and_preprocess_heart_data(raw_df)
    X, y, scaler = prepare_ml_features(cleaned_df)
    print(f"   Scaler created with {len(scaler.mean_)} features")

    # Save scaler for each existing model
    model_files = list(artifacts_dir.glob("*.pkl"))
    print(f"\n2. Found {len(model_files)} model files")

    for model_file in model_files:
        if "_scaler" not in model_file.name:  # Skip existing scaler files
            scaler_path = artifacts_dir / f"{model_file.stem}_scaler.pkl"

            with open(scaler_path, "wb") as f:
                pickle.dump(scaler, f)

            print(f"   ✓ Saved: {scaler_path.name}")

    print("\n" + "=" * 60)
    print("✓ Scaler files generated successfully!")
    print("\nVerify with: ls -lh artifacts/*_scaler.pkl")


if __name__ == "__main__":
    main()
