import pandas as pd

from MLOps_Assignment import (
    train_logistic_regression,
    train_random_forest,
    train_decision_tree,
    evaluate_classification_model,
    cross_validate_models,
)


def _make_tiny_dataset():
    df = pd.DataFrame(
        {
            "age": [60, 61, 62, 63, 64, 65],
            "sex": [1, 0, 1, 0, 1, 0],
            "cp": [1, 2, 3, 4, 1, 2],
            "trestbps": [120, 130, 140, 150, 160, 170],
            "chol": [200, 210, 220, 230, 240, 250],
            "fbs": [0, 0, 1, 0, 1, 0],
            "restecg": [0, 1, 0, 1, 0, 1],
            "thalach": [150, 145, 155, 148, 152, 149],
            "exang": [0, 1, 0, 1, 0, 1],
            "oldpeak": [1.0, 1.5, 0.5, 2.0, 1.2, 0.8],
            "slope": [2, 1, 2, 1, 2, 1],
            "ca": [0, 0, 1, 0, 2, 1],
            "thal": [3, 7, 3, 7, 3, 7],
            "target": [0, 1, 0, 1, 0, 1],
        }
    )
    X = df.drop(columns=["target"])
    y = df["target"]
    return X, y


def test_train_and_evaluate_models():
    X, y = _make_tiny_dataset()
    X_train, X_test = X.iloc[:4], X.iloc[4:]
    y_train, y_test = y.iloc[:4], y.iloc[4:]

    for train_fn, name in [
        (train_logistic_regression, "Logistic Regression"),
        (train_random_forest, "Random Forest"),
        (train_decision_tree, "Decision Tree"),
    ]:
        model = train_fn(X_train, y_train)
        metrics = evaluate_classification_model(model, X_train, y_train, X_test, y_test, model_name=name)
        # Basic sanity checks on metrics keys
        for key in [
            "train_accuracy",
            "test_accuracy",
            "test_precision",
            "test_recall",
            "test_f1",
            "test_roc_auc",
        ]:
            assert key in metrics


def test_cross_validate_models_runs():
    X, y = _make_tiny_dataset()
    # Use fewer splits for speed
    results_df = cross_validate_models(X, y, cv_splits=3, random_state=0)
    assert not results_df.empty
    # Expect rows for each model
    assert set(results_df["model"]) == {"Logistic Regression", "Random Forest", "Decision Tree"}
