FROM public.ecr.aws/lambda/python:3.10

COPY src/requirements.txt ${LAMBDA_TASK_ROOT}

RUN pip install -r requirements.txt

COPY src/ingestion.py ${LAMBDA_TASK_ROOT}

CMD [ "ingestion.lambda_handler" ]