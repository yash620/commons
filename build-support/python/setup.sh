#!/bin/bash

BASE_DIR=$(dirname $0)/../..
BOOTSTRAP_BIN=$BASE_DIR/.python/bin
BOOTSTRAP_ENVIRONMENT=$BASE_DIR/.python/bootstrap
CACHE=$BASE_DIR/.pants.d/.pip.cache
PY=$(which python)

mkdir -p $BOOTSTRAP_BIN
mkdir -p $BOOTSTRAP_ENVIRONMENT
mkdir -p $CACHE


if [ ! $PY ]; then
  echo 'No python interpreter found on the path.  Python will not work!'
  exit 1
fi

# Get Python version. For example, Python 2.7.1 -> 27
py_version=$($PY --version 2>&1 | awk -F' ' '{ print $2 }' | awk -F. '{ print $1$2 }')
if [ "${py_version}" -lt 26 ]; then
  echo 'Python interpreter needs to be version 2.6+.'
  exit 2
fi

if ! test -f $BOOTSTRAP_BIN/bootstrap; then
  ln -s $PY $BOOTSTRAP_BIN/bootstrap
fi

PYTHON=$BOOTSTRAP_BIN/bootstrap

VIRTUALENV=virtualenv-1.9.1
VIRTUALENV_DIST=${VIRTUALENV}.tar.gz

pushd $CACHE >& /dev/null
  if ! test -f $VIRTUALENV_DIST; then
    echo 'Installing virtualenv' 1>&2
    for url in \
      https://pypi.python.org/packages/source/v/virtualenv/$VIRTUALENV_DIST \
      https://svn.twitter.biz/science-binaries/home/third_party/python/$VIRTUALENV_DIST; do
      if curl --connect-timeout 10 -O $url; then
        break
      fi
    done
  fi
  gzip -cd $VIRTUALENV_DIST | tar -xf - >& /dev/null
popd >& /dev/null

if $PYTHON $CACHE/$VIRTUALENV/virtualenv.py -p $PY --distribute $BOOTSTRAP_ENVIRONMENT; then
  source $BOOTSTRAP_ENVIRONMENT/bin/activate
  for pkg in distribute pystache; do
    pip install \
      --download-cache=$CACHE \
      -f https://svn.twitter.biz/science-binaries/home/third_party/python \
      -f http://pypi.python.org/simple \
      -U --no-index $pkg
  done
  deactivate
fi
