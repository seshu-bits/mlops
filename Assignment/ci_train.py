from pathlib import Path

import mlflow

from MLOps_Assignment import (
    load_raw_heart_data,
    clean_and_preprocess_heart_data,
    prepare_ml_features,
    train_test_split_features,
    train_logistic_regression,
    evaluate_classification_model,
    save_final_model,
)


def main():
    data_dir = Path("./data")

    # Minimal: assume data is already downloaded as processed.cleveland.data
    # In CI, you can either commit a small sample or add a download step here.

    raw_df = load_raw_heart_data(data_dir=data_dir)
    cleaned_df = clean_and_preprocess_heart_data(raw_df)
    X, y, scaler = prepare_ml_features(cleaned_df)
    X_train, X_test, y_train, y_test = train_test_split_features(X, y)

    mlflow.set_experiment("ci_heart_disease_classification")

    with mlflow.start_run(run_name="ci_logistic_regression"):
        model = train_logistic_regression(X_train, y_train)
        metrics = evaluate_classification_model(
            model, X_train, y_train, X_test, y_test, model_name="Logistic Regression"
        )

        # Log metrics
        for k, v in metrics.items():
            mlflow.log_metric(k, float(v))

        # Save model and log to MLflow
        save_final_model(
            model,
            model_name="Logistic Regression CI",
            output_dir="artifacts_ci",
            save_pickle=True,
            save_mlflow=True,
            save_onnx=False,
            X_sample=X_train.iloc[:10],
        )

        # Also log scaler parameters as simple artifacts/params
        mlflow.log_param("scaler_mean_len", len(scaler.mean_))
        mlflow.log_param("train_rows", len(X_train))
        mlflow.log_param("test_rows", len(X_test))


if __name__ == "__main__":
    main()