FROM jupyter/base-notebook

USER root

RUN apt update && apt-get install unzip

RUN pip install pandas kaggle

USER jovyan