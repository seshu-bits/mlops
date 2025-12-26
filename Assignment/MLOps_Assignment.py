from __future__ import annotations

from pathlib import Path
from typing import Tuple

import matplotlib.pyplot as plt
import mlflow
import mlflow.sklearn
import numpy as np
import pandas as pd
import seaborn as sns
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import StratifiedKFold, cross_validate, train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.tree import DecisionTreeClassifier


# ==========================
# Data loading & processing
# ==========================


def load_raw_heart_data(data_dir: str | Path = "./data") -> pd.DataFrame:
    """Load the raw Heart Disease dataset from the local directory.

    This mirrors the logic in the notebook: expects a file named
    ``processed.cleveland.data`` in ``data_dir`` and assigns the
    standard Cleveland column names.
    """

    data_dir = Path(data_dir)
    data_file = data_dir / "processed.cleveland.data"
    if not data_file.exists():
        raise FileNotFoundError(
            f"Expected file '{data_file.name}' not found in {data_dir}. "
            "Make sure the dataset was downloaded and extracted correctly."
        )

    column_names = [
        "age",
        "sex",
        "cp",
        "trestbps",
        "chol",
        "fbs",
        "restecg",
        "thalach",
        "exang",
        "oldpeak",
        "slope",
        "ca",
        "thal",
        "target",
    ]

    df = pd.read_csv(data_file, header=None, names=column_names)
    return df


def clean_and_preprocess_heart_data(df: pd.DataFrame) -> pd.DataFrame:
    """Clean the Heart Disease data (missing values + numeric conversion + binary target).

    - Replace '?' with NaN
    - Convert non-target columns to numeric where possible
    - Drop rows with any missing values
    - Binarize 'target' (0 = no disease, 1 = disease)
    """

    # Replace UCI missing-value marker '?' with NaN
    df = df.replace("?", pd.NA)

    # Convert all non-target columns to numeric safely
    for col in df.columns:
        if col == "target":
            continue
        try:
            df[col] = pd.to_numeric(df[col])
        except Exception:
            # If conversion fails entirely, leave column as-is (treated as categorical)
            pass

    # Drop rows with any missing values
    df = df.dropna().reset_index(drop=True)

    # Ensure target is binary: in Cleveland data, values > 0 indicate presence of disease
    if "target" in df.columns:
        df["target"] = (df["target"] > 0).astype(int)
    else:
        raise KeyError("Expected 'target' column in dataframe")

    return df


def prepare_ml_features(
    df: pd.DataFrame,
    scaler: StandardScaler | None = None,
) -> Tuple[pd.DataFrame, pd.Series, StandardScaler]:
    """Prepare final ML features (encoding + scaling) from a CLEANED dataframe.

    - Splits into X/y
    - One-hot encodes non-numeric columns
    - Applies StandardScaler to numeric columns
    """

    if "target" not in df.columns:
        raise KeyError("Expected 'target' column in dataframe for feature preparation")

    X = df.drop(columns=["target"])
    y = df["target"]

    numeric_cols = X.select_dtypes(include=["int64", "float64", "Int64", "Float64"]).columns
    categorical_cols = [c for c in X.columns if c not in numeric_cols]

    if categorical_cols:
        X = pd.get_dummies(X, columns=categorical_cols, drop_first=True)

    if scaler is None:
        scaler = StandardScaler()
        X[numeric_cols] = scaler.fit_transform(X[numeric_cols])
    else:
        X[numeric_cols] = scaler.transform(X[numeric_cols])

    return X, y, scaler


def train_test_split_features(
    X: pd.DataFrame,
    y: pd.Series,
    test_size: float = 0.2,
    random_state: int = 42,
) -> Tuple[pd.DataFrame, pd.DataFrame, pd.Series, pd.Series]:
    """Perform a stratified train/test split on prepared features."""

    return train_test_split(
        X,
        y,
        test_size=test_size,
        random_state=random_state,
        stratify=y,
    )


# ==========================
# Modeling
# ==========================


def train_logistic_regression(X_train, y_train):
    """Build and train a Logistic Regression classifier on the training data."""

    model = LogisticRegression(max_iter=1000, n_jobs=-1, solver="lbfgs")
    model.fit(X_train, y_train)
    return model


def train_random_forest(
    X_train,
    y_train,
    n_estimators: int = 200,
    random_state: int = 42,
):
    """Build and train a Random Forest classifier on the training data."""

    model = RandomForestClassifier(
        n_estimators=n_estimators,
        random_state=random_state,
        n_jobs=-1,
        class_weight="balanced",
    )
    model.fit(X_train, y_train)
    return model


def train_decision_tree(
    X_train,
    y_train,
    max_depth: int | None = None,
    random_state: int = 42,
):
    """Build and train a Decision Tree classifier on the training data."""

    model = DecisionTreeClassifier(
        max_depth=max_depth,
        random_state=random_state,
        class_weight="balanced",
    )
    model.fit(X_train, y_train)
    return model


def evaluate_classification_model(
    model,
    X_train,
    y_train,
    X_test,
    y_test,
    model_name: str = "Model",
) -> dict:
    """Evaluate a fitted binary classification model on train and test sets.

    Metrics: accuracy, precision, recall, F1-score, ROC-AUC (if available).
    Returns a dict of metrics.
    """

    y_train_pred = model.predict(X_train)
    y_test_pred = model.predict(X_test)

    if hasattr(model, "predict_proba"):
        y_test_proba = model.predict_proba(X_test)[:, 1]
        roc_auc = roc_auc_score(y_test, y_test_proba)
    else:
        roc_auc = float("nan")

    metrics = {
        "train_accuracy": accuracy_score(y_train, y_train_pred),
        "test_accuracy": accuracy_score(y_test, y_test_pred),
        "test_precision": precision_score(y_test, y_test_pred, zero_division=0),
        "test_recall": recall_score(y_test, y_test_pred, zero_division=0),
        "test_f1": f1_score(y_test, y_test_pred, zero_division=0),
        "test_roc_auc": roc_auc,
    }

    # The notebook prints a detailed report; tests only need the numbers
    return metrics


def cross_validate_models(
    X,
    y,
    cv_splits: int = 5,
    random_state: int = 42,
) -> pd.DataFrame:
    """Run cross-validation for Logistic Regression, Random Forest and Decision Tree.

    Uses StratifiedKFold and reports mean +/- std for:
    - accuracy
    - precision
    - recall
    - F1-score
    - ROC-AUC
    Returns a pandas DataFrame summarizing model selection metrics.
    """

    cv = StratifiedKFold(n_splits=cv_splits, shuffle=True, random_state=random_state)

    scoring = {
        "accuracy": "accuracy",
        "precision": "precision",
        "recall": "recall",
        "f1": "f1",
        "roc_auc": "roc_auc",
    }

    models = {
        "Logistic Regression": LogisticRegression(max_iter=1000, n_jobs=-1, solver="lbfgs"),
        "Random Forest": RandomForestClassifier(
            n_estimators=200,
            random_state=random_state,
            n_jobs=-1,
            class_weight="balanced",
        ),
        "Decision Tree": DecisionTreeClassifier(
            max_depth=None,
            random_state=random_state,
            class_weight="balanced",
        ),
    }

    rows = []
    for name, model in models.items():
        cv_results = cross_validate(
            model,
            X,
            y,
            cv=cv,
            scoring=scoring,
            return_train_score=False,
            n_jobs=-1,
        )

        row = {"model": name}
        for metric in scoring.keys():
            scores = cv_results[f"test_{metric}"]
            row[f"{metric}_mean"] = scores.mean()
            row[f"{metric}_std"] = scores.std()
        rows.append(row)

    results_df = pd.DataFrame(rows)
    return results_df


# ==========================
# MLflow helpers & model saving
# ==========================


def log_cv_results_to_mlflow(cv_results_df: pd.DataFrame):
    """Log cross-validation summary table as an MLflow artifact (CSV)."""

    cv_results_df.to_csv("cv_results_summary.csv", index=False)
    mlflow.log_artifact("cv_results_summary.csv", artifact_path="cv_results")


def log_model_run_to_mlflow(model_name: str, params: dict, metrics: dict):
    """Log parameters and metrics for a single trained model to MLflow."""

    mlflow.log_param("model_name", model_name)
    for p_name, p_val in params.items():
        mlflow.log_param(p_name, p_val)
    for m_name, m_val in metrics.items():
        mlflow.log_metric(m_name, float(m_val))


def log_confusion_matrix_plot(model, X_test, y_test, model_name: str):
    """Create and log a simple confusion matrix heatmap as an MLflow artifact."""

    from sklearn.metrics import confusion_matrix

    y_pred = model.predict(X_test)
    cm = confusion_matrix(y_test, y_pred)

    plt.figure(figsize=(4, 3))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Blues", cbar=False)
    plt.title(f"Confusion Matrix - {model_name}")
    plt.xlabel("Predicted")
    plt.ylabel("True")
    plt.tight_layout()
    plot_path = f"confusion_matrix_{model_name.replace(' ', '_').lower()}.png"
    plt.savefig(plot_path)
    plt.close()
    mlflow.log_artifact(plot_path, artifact_path="plots")


def save_final_model(
    model,
    model_name: str,
    output_dir: str | Path = "artifacts",
    save_pickle: bool = True,
    save_mlflow: bool = True,
    save_onnx: bool = False,
    X_sample=None,
):
    """Save the final trained model in multiple reusable formats.

    - Always supports local pickle and MLflow model logging (if an MLflow run is active)
    - Optionally supports ONNX export if ``skl2onnx`` is installed and ``X_sample`` is provided
    """

    import pickle

    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    safe_name = model_name.replace(" ", "_").lower()

    # 1. Local pickle
    if save_pickle:
        pkl_path = output_dir / f"{safe_name}.pkl"
        with open(pkl_path, "wb") as f:
            pickle.dump(model, f)

    # 2. MLflow model (if run is active)
    if save_mlflow:
        try:
            mlflow.sklearn.log_model(model, artifact_path=f"{safe_name}_mlflow_model")
        except Exception:
            # In tests we don't want this to crash if MLflow isn't fully configured
            pass

    # 3. Optional ONNX export
    if save_onnx:
        try:
            if X_sample is None:
                raise ValueError("X_sample must be provided to export ONNX model.")

            from skl2onnx import convert_sklearn
            from skl2onnx.common.data_types import FloatTensorType

            if hasattr(X_sample, "values"):
                X_np = X_sample.values.astype("float32")
            else:
                X_np = np.asarray(X_sample, dtype="float32")

            initial_type = [("input", FloatTensorType([None, X_np.shape[1]]))]
            onnx_model = convert_sklearn(model, initial_types=initial_type)
            onnx_path = output_dir / f"{safe_name}.onnx"
            with open(onnx_path, "wb") as f:
                f.write(onnx_model.SerializeToString())
        except Exception:
            # ONNX export is optional; swallow errors for robustness in tests
            pass
