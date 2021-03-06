.PHONY: test app venv clean clean-pyc clean-env clean-tests trained-model features

pennylane-env/bin/activate: requirements.txt
	test -d pennylane-env || virtualenv pennylane-env
	. pennylane-env/bin/activate; pip install -r requirements.txt
	touch pennylane-env/bin/activate

venv: pennylane-env/bin/activate

data/Admission_Predict.csv: src/load_data.py
	python src/load_data.py --bucket_name=123sasa --file_key=Admission_Predict.csv --output_file_path=data/Admission_Predict.csv
load_data: data/Admission_Predict.csv

data/admission_to_train.csv: data/Admission_Predict.csv src/generate_features.py
	python run.py generate_features --config=config/config.yaml --input=data/Admission_Predict.csv  --output=data/admission_to_train.csv
features: data/admission_to_train.csv

models/logreg.pkl: src/train_model.py
	python run.py train_model --config=config/config.yaml --input=data/admission_to_train.csv --output=models/logreg.pkl
train_model: models/logreg.pkl

models/admission_prediction.csv: data/admission-data--test-features.csv src/score_test_model.py
	python run.py score_test_model --config=config/config.yaml --input=data/admission-data--test-features.csv --output=models/admission_prediction.csv
score: models/admission_prediction.csv

models/model_evaluation.csv: models/admission_prediction.csv src/eval_model.py
	python run.py run_evaluate_model --config=config/config.yaml --Xtest=data/admission-data--test-features.csv --input=models/admission_prediction.csv --output=models/model_evaluation.csv
evaluate_model: models/model_evaluation.csv


test:
	pytest test/test.py



clean-tests:
	rm -rf .pytest_cache
	rm -r data
	mkdir data
	touch data/.gitkeep
	rm -r models
	mkdir models
	touch models/.gitkeep


clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +

clean: clean-tests clean-pyc

all: load_data features train_model score evaluate_model