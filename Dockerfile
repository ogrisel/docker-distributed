FROM debian:jessie
MAINTAINER Olivier Grisel <olivier.grisel@ensta.org>

RUN apt-get update -yqq  && apt-get install -yqq \
  wget \
  bzip2 \
  git \
  libglib2.0-0 \
  && rm -rf /var/lib/apt/lists/*

# Configure environment
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Folder to install non-system tools and serve as workspace for the notebook
# user
RUN mkdir -p /work/bin

# Create a non-priviledge user that will run the services
#ENV BASICUSER basicuser
#ENV BASICUSER_UID 1000
#RUN useradd -m -d /work -s /bin/bash -N -u $BASICUSER_UID $BASICUSER
#RUN chown $BASICUSER /work
#USER $BASICUSER

# Deactivate basic user to make it easier to deal with volume permissions
# for now
ENV BASICUSER root
WORKDIR /work

# Install Python 3 from miniconda
RUN wget -O miniconda.sh \
  https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
  && bash miniconda.sh -b -p /work/miniconda \
  && rm miniconda.sh

ENV PATH="/work/bin:/work/miniconda/bin:$PATH"


# Install matplotlib and scikit-image without Qt
RUN conda update -y python conda && \
  conda install -y --no-deps \
  matplotlib \
  cycler \
  freetype \
  libpng \
  pyparsing \
  pytz \
  python-dateutil \
  scikit-image \
  networkx \
  pillow \
  six \
  && conda clean -tipsy

RUN conda install -y \
  pip \
  setuptools \
  notebook \
  ipywidgets \
  terminado \
  psutil \
  numpy \
  scipy \
  pandas \
  bokeh \
  scikit-learn \
  statsmodels \
  && conda clean -tipsy


# Install the master branch of distributed and dask
COPY requirements.txt .
RUN pip install -r requirements.txt && rm -rf ~/.cache/pip/

# Add local files at the end of the Dockerfule to limit cache busting
COPY start-notebook.sh ./bin/
COPY start-dworker.sh ./bin/
COPY start-dscheduler.sh ./bin/
COPY examples examples

# Configure matplotlib to avoid using QT
COPY matplotlibrc /work/.config/matplotlib/matplotlibrc

# Trigger creation of the matplotlib font cache
ENV MATPLOTLIBRC /work/.config/matplotlib
RUN python -c "import matplotlib.pyplot"

# Switch back to root to make it possible to do interactive admin/debug as
# root tasks with docker exec
USER root
# Files added via COPY need a manual chown
RUN chown $BASICUSER:users -R /work/.config /work/examples /work/bin /work/requirements.txt

# Install Tini that necessary to properly run the notebook service in a docker
# container:
# http://jupyter-notebook.readthedocs.org/en/latest/public_server.html#docker-cmd
ENV TINI_VERSION v0.9.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]
