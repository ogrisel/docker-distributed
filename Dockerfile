FROM python:3.5
ADD . /code
WORKDIR /code
RUN pip install --upgrade pip setuptools
RUN pip install -r requirements.txt
CMD python app.py
