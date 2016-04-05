FROM debian:jessie
MAINTAINER Olivier Grisel <olivier.grisel@ensta.org>

RUN apt-get update -yqq  && apt-get install -yqq \
  wget \
  bzip2 \
  git \
  libglib2.0-0 \
  && rm -rf /var/lib/apt/lists/*

# Install Tini
# http://jupyter-notebook.readthedocs.org/en/latest/public_server.html#docker-cmd
ENV TINI_VERSION v0.9.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

# Configure environment
ENV BASICUSER basicuser
ENV BASICUSER_UID 1000

# Create a non-priviledge user that will run the services
RUN useradd -m -s /bin/bash -N -u $BASICUSER_UID $BASICUSER

ADD . /work
RUN mkdir /work/bin
WORKDIR /work
RUN chown -R basicuser /work
USER $BASICUSER
ENV HOME /work

# Install Python 3 from miniconda
RUN wget -O miniconda.sh \
  https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
  && bash miniconda.sh -b -p /work/miniconda \
  && rm miniconda.sh

ENV PATH="/work/bin:/work/miniconda/bin:$PATH"
RUN conda update -y python conda && conda install -y \
  pip \
  setuptools \
  notebook \
  ipywidgets \
  terminado \
  psutil \
  pandas \
  bokeh \
  && conda clean -yt

# Install the master branch of distributed and dask
RUN pip install -r requirements.txt

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
