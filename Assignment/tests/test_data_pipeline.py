import os
import sys
from pathlib import Path

import pandas as pd

# Add parent directory to path to import the module
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from MLOps_Assignment import (
    load_raw_heart_data,
    clean_and_preprocess_heart_data,
    prepare_ml_features,
    train_test_split_features,
)


def test_load_raw_heart_data(tmp_path: Path):
    """load_raw_heart_data should load a CSV with expected columns and stats."""
    # Create a tiny synthetic processed.cleveland.data in a temp dir
    data_dir = tmp_path
    data_file = data_dir / "processed.cleveland.data"
    df = pd.DataFrame(
        {
            "age": [63, 67],
            "sex": [1, 1],
            "cp": [1, 4],
            "trestbps": [145, 160],
            "chol": [233, 286],
            "fbs": [1, 0],
            "restecg": [2, 2],
            "thalach": [150, 108],
            "exang": [0, 1],
            "oldpeak": [2.3, 1.5],
            "slope": [3, 2],
            "ca": [0, 3],
            "thal": [6, 3],
            "target": [0, 2],
        }
    )
    df.to_csv(data_file, header=False, index=False)

    loaded = load_raw_heart_data(data_dir=data_dir)
    assert not loaded.empty
    assert set(loaded.columns) == set(df.columns)


def test_clean_and_preprocess_heart_data():
    raw = pd.DataFrame(
        {
            "age": ["63", "?"],
            "sex": ["1", "0"],
            "target": [0, 3],
        }
    )
    cleaned = clean_and_preprocess_heart_data(raw)

    # One row with missing age should be dropped
    assert cleaned.shape[0] == 1
    assert cleaned["age"].dtype != object
    # Target should be binarized
    assert set(cleaned["target"].unique()) <= {0, 1}


def test_prepare_ml_features_and_split():
    df = pd.DataFrame(
        {
            "age": [60, 61, 62, 63],
            "sex": [1, 0, 1, 0],
            "cp": [1, 2, 3, 4],
            "target": [0, 1, 0, 1],
        }
    )
    X, y, scaler = prepare_ml_features(df)

    # All non-target columns should be in X
    assert "target" not in X.columns
    assert list(y) == [0, 1, 0, 1]

    # Train/test split preserves size and stratification
    X_train, X_test, y_train, y_test = train_test_split_features(X, y, test_size=0.5, random_state=42)
    assert len(X_train) == len(y_train) == 2
    assert len(X_test) == len(y_test) == 2
    # Class balance should be preserved approximately
    assert y_train.nunique() == 2
    assert y_test.nunique() == 2
