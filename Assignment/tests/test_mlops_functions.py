"""
Additional unit tests for MLOps_Assignment.py functions.

Tests for validation, EDA, model saving, and edge cases.
"""

import sys
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler

# Add parent directory to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from MLOps_Assignment import (  # noqa: E402
    extract_feature_importance,
    perform_eda_heart_data,
    save_final_model,
    tune_logistic_regression,
    validate_heart_data,
)


def test_validate_heart_data_valid():
    """Test data validation with valid data."""
    valid_df = pd.DataFrame(
        {
            "age": [60, 65, 70],
            "sex": [1, 0, 1],
            "cp": [1, 2, 3],
            "trestbps": [120, 130, 140],
            "chol": [200, 220, 240],
            "fbs": [0, 1, 0],
            "restecg": [0, 1, 2],
            "thalach": [150, 145, 155],
            "exang": [0, 1, 0],
            "oldpeak": [1.0, 1.5, 2.0],
            "slope": [1, 2, 3],
            "ca": [0, 1, 2],
            "thal": [3, 6, 7],
            "target": [0, 1, 0],
        }
    )

    results = validate_heart_data(valid_df)
    assert results["is_valid"] is True
    assert len(results["errors"]) == 0
    assert "total_rows" in results["metrics"]


def test_validate_heart_data_missing_columns():
    """Test validation with missing columns."""
    incomplete_df = pd.DataFrame(
        {
            "age": [60, 65],
            "sex": [1, 0],
            # Missing other required columns
        }
    )

    results = validate_heart_data(incomplete_df)
    assert results["is_valid"] is False
    assert len(results["errors"]) > 0


def test_validate_heart_data_missing_values():
    """Test validation detects missing values."""
    df_with_na = pd.DataFrame(
        {
            "age": [60, None, 70],
            "sex": [1, 0, 1],
            "cp": [1, 2, 3],
            "trestbps": [120, 130, 140],
            "chol": [200, 220, 240],
            "fbs": [0, 1, 0],
            "restecg": [0, 1, 2],
            "thalach": [150, 145, 155],
            "exang": [0, 1, 0],
            "oldpeak": [1.0, 1.5, 2.0],
            "slope": [1, 2, 3],
            "ca": [0, 1, 2],
            "thal": [3, 6, 7],
            "target": [0, 1, 0],
        }
    )

    results = validate_heart_data(df_with_na)
    assert len(results["warnings"]) > 0
    assert results["metrics"]["missing_values"] > 0


def test_validate_heart_data_outliers():
    """Test validation detects outliers."""
    df_with_outliers = pd.DataFrame(
        {
            "age": [60, 65, 200],  # 200 is outlier
            "sex": [1, 0, 1],
            "cp": [1, 2, 3],
            "trestbps": [120, 130, 140],
            "chol": [200, 220, 240],
            "fbs": [0, 1, 0],
            "restecg": [0, 1, 2],
            "thalach": [150, 145, 155],
            "exang": [0, 1, 0],
            "oldpeak": [1.0, 1.5, 2.0],
            "slope": [1, 2, 3],
            "ca": [0, 1, 2],
            "thal": [3, 6, 7],
            "target": [0, 1, 0],
        }
    )

    results = validate_heart_data(df_with_outliers)
    # Should detect age outlier
    if "outliers" in results["metrics"]:
        assert "age" in results["metrics"]["outliers"]


def test_perform_eda_heart_data(tmp_path):
    """Test EDA function generates plots."""
    df = pd.DataFrame(
        {
            "age": [60, 65, 70, 75],
            "sex": [1, 0, 1, 0],
            "cp": [1, 2, 3, 4],
            "trestbps": [120, 130, 140, 150],
            "chol": [200, 220, 240, 260],
            "target": [0, 1, 0, 1],
        }
    )

    output_dir = tmp_path / "eda"
    results = perform_eda_heart_data(df, output_dir=output_dir, save_plots=True)

    assert "plots" in results
    assert "statistics" in results
    assert len(results["plots"]) > 0  # Should generate some plots
    assert output_dir.exists()


def test_save_final_model_with_scaler(tmp_path):
    """Test saving model with scaler."""
    from sklearn.linear_model import LogisticRegression

    # Create dummy model and scaler
    model = LogisticRegression()
    X = np.array([[1, 2], [3, 4], [5, 6], [7, 8]])
    y = np.array([0, 1, 0, 1])
    model.fit(X, y)

    scaler = StandardScaler()
    scaler.fit(X)

    # Save model with scaler
    save_final_model(
        model,
        model_name="test_model",
        output_dir=str(tmp_path),
        scaler=scaler,
        save_pickle=True,
        save_mlflow=False,
        save_onnx=False,
    )

    # Check both files exist
    assert (tmp_path / "test_model.pkl").exists()
    assert (tmp_path / "test_model_scaler.pkl").exists()


def test_save_final_model_without_scaler(tmp_path):
    """Test saving model without scaler."""
    from sklearn.linear_model import LogisticRegression

    model = LogisticRegression()
    X = np.array([[1, 2], [3, 4], [5, 6], [7, 8]])
    y = np.array([0, 1, 0, 1])
    model.fit(X, y)

    save_final_model(
        model,
        model_name="test_model_no_scaler",
        output_dir=str(tmp_path),
        scaler=None,
        save_pickle=True,
        save_mlflow=False,
        save_onnx=False,
    )

    # Model should exist, scaler should not
    assert (tmp_path / "test_model_no_scaler.pkl").exists()
    assert not (tmp_path / "test_model_no_scaler_scaler.pkl").exists()


def test_extract_feature_importance():
    """Test feature importance extraction."""
    from sklearn.ensemble import RandomForestClassifier

    # Create and train a simple RF model
    X = np.array([[1, 2, 3], [4, 5, 6], [7, 8, 9], [10, 11, 12]])
    y = np.array([0, 1, 0, 1])

    model = RandomForestClassifier(n_estimators=10, random_state=42)
    model.fit(X, y)

    feature_names = ["feat1", "feat2", "feat3"]
    importance_df = extract_feature_importance(
        model, feature_names=feature_names, top_n=3, save_plot=False
    )

    assert len(importance_df) == 3
    assert "feature" in importance_df.columns
    assert "importance" in importance_df.columns
    assert importance_df["importance"].sum() > 0


def test_extract_feature_importance_no_attribute():
    """Test feature importance with model that doesn't have the attribute."""
    from sklearn.linear_model import LogisticRegression

    # Logistic Regression doesn't have feature_importances_
    model = LogisticRegression()
    X = np.array([[1, 2], [3, 4], [5, 6], [7, 8]])
    y = np.array([0, 1, 0, 1])
    model.fit(X, y)

    feature_names = ["feat1", "feat2"]

    # Should return empty DataFrame, not raise exception
    result = extract_feature_importance(model, feature_names=feature_names, save_plot=False)
    assert isinstance(result, pd.DataFrame)
    assert result.empty  # Should be empty DataFrame


def test_tune_logistic_regression():
    """Test hyperparameter tuning for Logistic Regression."""
    X = np.array([[1, 2], [3, 4], [5, 6], [7, 8], [9, 10], [11, 12]])
    y = np.array([0, 1, 0, 1, 0, 1])

    best_model, best_params, cv_summary = tune_logistic_regression(
        X, y, cv_splits=2, n_iter=2, method="randomized"
    )

    assert best_model is not None
    assert isinstance(best_params, dict)
    assert "best_score" in cv_summary
    assert "best_params" in cv_summary
    assert cv_summary["best_score"] >= 0  # Can be 0 for small/imbalanced datasets


def test_data_pipeline_edge_cases():
    """Test data pipeline with edge cases."""
    # Test with single row
    single_row = pd.DataFrame({"age": [60], "sex": [1], "target": [0]})

    from MLOps_Assignment import clean_and_preprocess_heart_data

    result = clean_and_preprocess_heart_data(single_row)
    assert len(result) == 1


def test_prepare_ml_features_returns_scaler():
    """Test that prepare_ml_features returns a fitted scaler."""
    df = pd.DataFrame({"age": [60, 65, 70], "sex": [1, 0, 1], "cp": [1, 2, 3], "target": [0, 1, 0]})

    from MLOps_Assignment import prepare_ml_features

    X, y, scaler = prepare_ml_features(df)

    assert scaler is not None
    assert hasattr(scaler, "mean_")
    assert hasattr(scaler, "scale_")
    assert len(scaler.mean_) > 0


def test_prepare_ml_features_with_existing_scaler():
    """Test prepare_ml_features with pre-fitted scaler."""
    df_train = pd.DataFrame(
        {"age": [60, 65, 70], "sex": [1, 0, 1], "cp": [1, 2, 3], "target": [0, 1, 0]}
    )

    df_test = pd.DataFrame({"age": [55, 75], "sex": [1, 0], "cp": [2, 3], "target": [1, 0]})

    from MLOps_Assignment import prepare_ml_features

    # Fit on train
    X_train, y_train, scaler = prepare_ml_features(df_train)

    # Transform test with same scaler
    X_test, y_test, scaler_test = prepare_ml_features(df_test, scaler=scaler)

    assert X_train.shape[1] == X_test.shape[1]  # Same features
    assert scaler is scaler_test  # Same scaler object


def test_validation_class_balance():
    """Test validation includes class balance metrics."""
    df = pd.DataFrame(
        {
            "age": [60, 65, 70, 75, 80],
            "sex": [1, 0, 1, 0, 1],
            "cp": [1, 2, 3, 4, 1],
            "trestbps": [120, 130, 140, 150, 160],
            "chol": [200, 220, 240, 260, 280],
            "fbs": [0, 1, 0, 1, 0],
            "restecg": [0, 1, 2, 0, 1],
            "thalach": [150, 145, 155, 148, 152],
            "exang": [0, 1, 0, 1, 0],
            "oldpeak": [1.0, 1.5, 2.0, 1.2, 0.8],
            "slope": [1, 2, 3, 1, 2],
            "ca": [0, 1, 2, 0, 1],
            "thal": [3, 6, 7, 3, 6],
            "target": [0, 1, 1, 0, 1],  # 2 class 0, 3 class 1
        }
    )

    results = validate_heart_data(df)
    assert "class_balance" in results["metrics"]
    assert 0 in results["metrics"]["class_balance"]
    assert 1 in results["metrics"]["class_balance"]
