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
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import StratifiedKFold, cross_validate, train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.tree import DecisionTreeClassifier

try:
    import requests
    from io import BytesIO
    from zipfile import ZipFile
    REQUESTS_AVAILABLE = True
except ImportError:
    REQUESTS_AVAILABLE = False


# ==========================
# Data Acquisition
# ==========================


def download_heart_disease_dataset(
    save_dir: str | Path = "./data",
    force_download: bool = False,
) -> Path:
    """Download the Heart Disease UCI Dataset and return the data directory.

    Downloads the official UCI Heart Disease archive ZIP, extracts it into
    ``save_dir``, and returns the path containing files like ``processed.cleveland.data``.

    Args:
        save_dir: Directory to save the dataset
        force_download: If True, download even if data already exists

    Returns:
        Path to the data directory

    Raises:
        ImportError: If requests library is not installed
        FileNotFoundError: If expected data files are not found after download
    """
    if not REQUESTS_AVAILABLE:
        raise ImportError(
            "The 'requests' library is required for downloading datasets. "
            "Install it with: pip install requests"
        )

    save_path = Path(save_dir)
    save_path.mkdir(parents=True, exist_ok=True)

    # If data directory already has the key files, reuse it
    key_file = save_path / "processed.cleveland.data"
    if key_file.exists() and not force_download:
        print(f"Dataset already present at: {save_path}")
        return save_path

    url = "https://archive.ics.uci.edu/static/public/45/heart+disease.zip"

    try:
        print("Downloading Heart Disease dataset from UCI Repository...")
        response = requests.get(url, timeout=60)
        response.raise_for_status()

        print(f"Extracting dataset to: {save_path}")
        with ZipFile(BytesIO(response.content)) as zip_file:
            zip_file.extractall(save_path)

        # After extraction, confirm key file(s) exist
        if not key_file.exists():
            # Some mirrors may have slightly different names; fall back to any *.data file
            data_candidates = list(save_path.glob("*.data"))
            if not data_candidates:
                raise FileNotFoundError(
                    f"Expected 'processed.cleveland.data' or any '*.data' file in {save_path}, "
                    "but none were found after extraction."
                )
            else:
                print("Warning: 'processed.cleveland.data' not found; using first .data file present.")

        files = list(save_path.glob("*"))
        print(f"\nDataset directory: {save_path}")
        print(f"Contains {len(files)} items:")
        for f in sorted(files)[:20]:
            print(f"  - {f.name}")
        if len(files) > 20:
            print(f"  ... and {len(files) - 20} more")

        return save_path

    except requests.exceptions.RequestException as e:
        print(f"✗ Error downloading dataset: {e}")
        raise
    except Exception as e:
        print(f"✗ Error extracting dataset: {e}")
        raise


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


def validate_heart_data(df: pd.DataFrame) -> dict:
    """Validate data quality and return validation metrics.

    Performs:
    - Schema validation (expected columns)
    - Data type checks
    - Range validation for numeric features
    - Missing value detection
    - Outlier detection using IQR method
    """
    validation_results = {
        "is_valid": True,
        "errors": [],
        "warnings": [],
        "metrics": {},
    }

    # Expected schema
    expected_columns = [
        "age", "sex", "cp", "trestbps", "chol", "fbs", "restecg",
        "thalach", "exang", "oldpeak", "slope", "ca", "thal", "target"
    ]

    # 1. Schema validation
    missing_cols = set(expected_columns) - set(df.columns)
    extra_cols = set(df.columns) - set(expected_columns)

    if missing_cols:
        validation_results["errors"].append(f"Missing columns: {missing_cols}")
        validation_results["is_valid"] = False

    if extra_cols:
        validation_results["warnings"].append(f"Extra columns found: {extra_cols}")

    # 2. Missing values check
    missing_counts = df.isnull().sum()
    if missing_counts.any():
        validation_results["warnings"].append(
            f"Missing values found: {missing_counts[missing_counts > 0].to_dict()}"
        )

    # 3. Range validation for key numeric features
    range_checks = {
        "age": (0, 120),
        "trestbps": (50, 250),  # resting blood pressure
        "chol": (100, 600),  # cholesterol
        "thalach": (50, 250),  # max heart rate
        "oldpeak": (0, 10),  # ST depression
    }

    for col, (min_val, max_val) in range_checks.items():
        if col in df.columns:
            out_of_range = df[(df[col] < min_val) | (df[col] > max_val)]
            if len(out_of_range) > 0:
                validation_results["warnings"].append(
                    f"{col}: {len(out_of_range)} values outside expected range [{min_val}, {max_val}]"
                )

    # 4. Outlier detection using IQR
    numeric_cols = df.select_dtypes(include=["int64", "float64", "Int64", "Float64"]).columns
    outlier_summary = {}

    for col in numeric_cols:
        if col == "target":
            continue
        Q1 = df[col].quantile(0.25)
        Q3 = df[col].quantile(0.75)
        IQR = Q3 - Q1
        lower_bound = Q1 - 1.5 * IQR
        upper_bound = Q3 + 1.5 * IQR
        outliers = df[(df[col] < lower_bound) | (df[col] > upper_bound)]
        if len(outliers) > 0:
            outlier_summary[col] = len(outliers)

    if outlier_summary:
        validation_results["metrics"]["outliers"] = outlier_summary
        validation_results["warnings"].append(f"Outliers detected (IQR method): {outlier_summary}")

    # 5. Data quality metrics
    validation_results["metrics"]["total_rows"] = len(df)
    validation_results["metrics"]["total_columns"] = len(df.columns)
    validation_results["metrics"]["missing_values"] = df.isnull().sum().sum()
    validation_results["metrics"]["duplicate_rows"] = df.duplicated().sum()

    if "target" in df.columns:
        validation_results["metrics"]["class_balance"] = df["target"].value_counts().to_dict()

    return validation_results


def perform_eda_heart_data(
    df: pd.DataFrame,
    output_dir: str | Path = "./artifacts/eda",
    save_plots: bool = True,
) -> dict:
    """Perform comprehensive EDA with professional visualizations.

    Creates and optionally saves:
    - Histograms for numerical features with KDE
    - Correlation heatmap
    - Class balance bar plot
    - Box plots of key features by target
    - Outlier detection visualization
    - Feature distribution summary

    Returns:
    - Dictionary with EDA statistics and plot paths
    """
    output_dir = Path(output_dir)
    if save_plots:
        output_dir.mkdir(parents=True, exist_ok=True)

    eda_results = {
        "plots": [],
        "statistics": {},
    }

    sns.set(style="whitegrid", context="notebook")

    # 1. Enhanced Histograms for numerical features
    numeric_cols = df.select_dtypes(include=["int64", "float64", "Int64", "Float64"]).columns
    if len(numeric_cols) > 0:
        n_cols = 3
        n_rows = int((len(numeric_cols) + n_cols - 1) / n_cols)
        fig, axes = plt.subplots(n_rows, n_cols, figsize=(15, 4 * n_rows))
        axes = axes.flatten() if n_rows > 1 else [axes]

        for i, col in enumerate(numeric_cols):
            sns.histplot(df[col].dropna(), kde=True, bins=30, color="#3498db",
                        edgecolor="black", alpha=0.7, ax=axes[i])
            axes[i].set_title(f"Distribution of {col.upper()}", fontsize=12, fontweight="bold")
            axes[i].set_xlabel(col, fontsize=10)
            axes[i].set_ylabel("Frequency", fontsize=10)
            axes[i].grid(axis="y", alpha=0.3)

        # Hide extra subplots
        for j in range(i + 1, len(axes)):
            axes[j].set_visible(False)

        plt.tight_layout()
        if save_plots:
            plot_path = output_dir / "histograms_numerical_features.png"
            plt.savefig(plot_path, dpi=150, bbox_inches="tight")
            eda_results["plots"].append(str(plot_path))
        plt.close()

    # 2. Enhanced Correlation heatmap
    if len(numeric_cols) > 1:
        plt.figure(figsize=(12, 10))
        corr = df[numeric_cols].corr()
        mask = np.triu(np.ones_like(corr, dtype=bool), k=1)
        sns.heatmap(corr, mask=mask, annot=True, fmt=".2f", cmap="RdYlBu_r",
                   center=0, square=True, linewidths=1, cbar_kws={"shrink": 0.8})
        plt.title("Correlation Heatmap (Numerical Features)", fontsize=14, fontweight="bold", pad=20)
        plt.tight_layout()
        if save_plots:
            plot_path = output_dir / "correlation_heatmap.png"
            plt.savefig(plot_path, dpi=150, bbox_inches="tight")
            eda_results["plots"].append(str(plot_path))
        plt.close()

    # 3. Enhanced Class balance with percentages
    if "target" in df.columns:
        fig, ax = plt.subplots(figsize=(8, 6))
        target_counts = df["target"].value_counts().sort_index()
        colors = ["#2ecc71", "#e74c3c"]
        bars = ax.bar(target_counts.index, target_counts.values, color=colors,
                     edgecolor="black", linewidth=1.5, alpha=0.8)

        # Add value labels on bars
        for bar in bars:
            height = bar.get_height()
            percentage = (height / len(df)) * 100
            ax.text(bar.get_x() + bar.get_width() / 2., height,
                   f"{int(height)}\n({percentage:.1f}%)",
                   ha="center", va="bottom", fontsize=11, fontweight="bold")

        ax.set_title("Target Variable Distribution", fontsize=14, fontweight="bold", pad=20)
        ax.set_xlabel("Target (0 = No Disease, 1 = Disease)", fontsize=11, fontweight="bold")
        ax.set_ylabel("Count", fontsize=11, fontweight="bold")
        ax.set_xticks(sorted(target_counts.index.tolist()))
        ax.grid(axis="y", alpha=0.3)
        plt.tight_layout()
        if save_plots:
            plot_path = output_dir / "class_balance.png"
            plt.savefig(plot_path, dpi=150, bbox_inches="tight")
            eda_results["plots"].append(str(plot_path))
        plt.close()

        eda_results["statistics"]["class_distribution"] = target_counts.to_dict()

    # 4. Box plots for key features by target
    if "target" in df.columns and len(numeric_cols) > 1:
        key_features = ["age", "trestbps", "chol", "thalach", "oldpeak"]
        available_features = [f for f in key_features if f in numeric_cols]

        if available_features:
            fig, axes = plt.subplots(1, len(available_features),
                                    figsize=(5 * len(available_features), 5))
            if len(available_features) == 1:
                axes = [axes]

            for i, feature in enumerate(available_features):
                sns.boxplot(x="target", y=feature, data=df, ax=axes[i], palette="Set2")
                axes[i].set_title(f"{feature.upper()} by Target", fontsize=11, fontweight="bold")
                axes[i].set_xlabel("Target", fontsize=10)
                axes[i].set_ylabel(feature, fontsize=10)

            plt.tight_layout()
            if save_plots:
                plot_path = output_dir / "boxplots_by_target.png"
                plt.savefig(plot_path, dpi=150, bbox_inches="tight")
                eda_results["plots"].append(str(plot_path))
            plt.close()

    # 5. Outlier detection visualization
    if len(numeric_cols) > 1:
        outlier_cols = [col for col in numeric_cols if col != "target"][:6]  # Limit to 6
        if outlier_cols:
            fig, axes = plt.subplots(2, 3, figsize=(15, 8))
            axes = axes.flatten()

            for i, col in enumerate(outlier_cols):
                Q1 = df[col].quantile(0.25)
                Q3 = df[col].quantile(0.75)
                IQR = Q3 - Q1
                lower_bound = Q1 - 1.5 * IQR
                upper_bound = Q3 + 1.5 * IQR

                # Plot data with outlier bounds
                axes[i].scatter(range(len(df)), df[col], alpha=0.5, s=10)
                axes[i].axhline(y=upper_bound, color="r", linestyle="--", label="Upper Bound")
                axes[i].axhline(y=lower_bound, color="r", linestyle="--", label="Lower Bound")
                axes[i].set_title(f"{col.upper()} - Outlier Detection", fontsize=10, fontweight="bold")
                axes[i].set_xlabel("Index", fontsize=9)
                axes[i].set_ylabel(col, fontsize=9)
                axes[i].legend(fontsize=8)

            # Hide extra subplots
            for j in range(len(outlier_cols), 6):
                axes[j].set_visible(False)

            plt.tight_layout()
            if save_plots:
                plot_path = output_dir / "outlier_detection.png"
                plt.savefig(plot_path, dpi=150, bbox_inches="tight")
                eda_results["plots"].append(str(plot_path))
            plt.close()

    # 6. Statistical summary
    eda_results["statistics"]["summary_stats"] = df.describe().to_dict()
    eda_results["statistics"]["missing_values"] = df.isnull().sum().to_dict()
    eda_results["statistics"]["data_types"] = df.dtypes.astype(str).to_dict()

    return eda_results


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
