FROM alpine
MAINTAINER Olivier Grisel <olivier.grisel@ensta.org>

# Install cURL
RUN apk --update add curl ca-certificates tar bzip2 git bash \
  && curl -o /tmp/glibc-2.21-r2.apk \
    https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/glibc-2.21-r2.apk \
  && apk add --allow-untrusted /tmp/glibc-2.21-r2.apk \
  && rm /tmp/glibc-2.21-r2.apk \
  && /usr/glibc/usr/bin/ldconfig /lib /usr/glibc/usr/lib

# Install Tini
# http://jupyter-notebook.readthedocs.org/en/latest/public_server.html#docker-cmd
ENV TINI_VERSION v0.9.0
RUN curl -o /usr/bin/tini \
  https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini \
  && chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

ADD . /work
RUN mkdir /work/bin
WORKDIR /work
ENV HOME /work

# Install Python 3 from miniconda
RUN curl -o miniconda.sh \
  https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
  && bash miniconda.sh -b -p /work/miniconda \
  && rm miniconda.sh

ENV PATH="/work/bin:/work/miniconda/bin:$PATH"
RUN conda update -y conda && conda install -y \
  pip \
  setuptools \
  notebook \
  ipywidgets \
  terminado \
  && conda clean -yt

# Install the master branch of distributed and dask
RUN pip install -r requirements.txt

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
