import os
import glob
import importlib.util
import pytest

DAG_FOLDER = os.path.join(os.path.dirname(__file__), "..", "dags")
DAG_FILES = glob.glob(os.path.join(DAG_FOLDER, "*.py"))


@pytest.mark.parametrize("dag_path", DAG_FILES)
def test_dag_import_errors(dag_path):
    """
    Ensure all Airflow DAG python files can be imported without raising errors.
    If airflow is not installed in the local runner environment, skip execution.
    """
    if os.path.basename(dag_path).startswith("__"):
        return

    try:
        import airflow
    except ImportError:
        pytest.skip("Airflow is not installed in the local environment.")

    module_name = os.path.basename(dag_path).replace(".py", "")
    spec = importlib.util.spec_from_file_location(module_name, dag_path)
    module = importlib.util.module_from_spec(spec)

    try:
        spec.loader.exec_module(module)
    except Exception as e:
        pytest.fail(f"DAG import failed for file {dag_path} with error: {e}")

