from pathlib import Path

import mlflow

from MLOps_Assignment import (
    load_raw_heart_data,
    clean_and_preprocess_heart_data,
    validate_heart_data,
    perform_eda_heart_data,
    prepare_ml_features,
    train_test_split_features,
    train_logistic_regression,
    evaluate_classification_model,
    save_final_model,
)


def main():
    data_dir = Path("./data")
    artifacts_dir = Path("./artifacts_ci")
    artifacts_dir.mkdir(parents=True, exist_ok=True)

    # Minimal: assume data is already downloaded as processed.cleveland.data
    # In CI, you can either commit a small sample or add a download step here.

    raw_df = load_raw_heart_data(data_dir=data_dir)

    # Validate data quality
    print("\n" + "=" * 60)
    print("DATA VALIDATION")
    print("=" * 60)
    validation_results = validate_heart_data(raw_df)
    print(f"Valid: {validation_results['is_valid']}")
    if validation_results['errors']:
        print(f"Errors: {validation_results['errors']}")
    if validation_results['warnings']:
        print(f"Warnings: {validation_results['warnings']}")
    print(f"Metrics: {validation_results['metrics']}")

    cleaned_df = clean_and_preprocess_heart_data(raw_df)

    # Perform EDA and save artifacts
    print("\n" + "=" * 60)
    print("EXPLORATORY DATA ANALYSIS")
    print("=" * 60)
    eda_results = perform_eda_heart_data(
        cleaned_df,
        output_dir=artifacts_dir / "eda",
        save_plots=True
    )
    print(f"EDA plots saved: {len(eda_results['plots'])} plots")
    for plot in eda_results['plots']:
        print(f"  - {plot}")

    X, y, scaler = prepare_ml_features(cleaned_df)
    X_train, X_test, y_train, y_test = train_test_split_features(X, y)

    mlflow.set_experiment("ci_heart_disease_classification")

    with mlflow.start_run(run_name="ci_logistic_regression"):
        # Log validation metrics
        mlflow.log_params({
            "data_validation_passed": validation_results['is_valid'],
            "total_rows": validation_results['metrics'].get('total_rows', 0),
            "missing_values": validation_results['metrics'].get('missing_values', 0),
            "duplicate_rows": validation_results['metrics'].get('duplicate_rows', 0),
        })

        # Log EDA artifacts to MLflow
        for plot_path in eda_results['plots']:
            mlflow.log_artifact(plot_path, artifact_path="eda")

        # Log class distribution
        if 'class_distribution' in eda_results['statistics']:
            for cls, count in eda_results['statistics']['class_distribution'].items():
                mlflow.log_metric(f"class_{cls}_count", count)

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

    print("\n" + "=" * 60)
    print("TRAINING COMPLETE")
    print("=" * 60)


if __name__ == "__main__":
    main()
