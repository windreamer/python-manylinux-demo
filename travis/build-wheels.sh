#!/bin/bash
set -e -x

# Install a system package required by our library
yum install -y atlas-devel

mkdir -p /opt/python/pypy /opt/python/pypy3
wget "https://bitbucket.org/squeaky/portable-pypy/downloads/pypy-5.6-linux_$(uname -m)-portable.tar.bz2" -qO - | tar xj -C /opt/python/pypy/
wget "https://bitbucket.org/squeaky/portable-pypy/downloads/pypy3.3-5.5-alpha-20161013-linux_i$(uname -m)-portable.tar.bz2" -qO - | tar xj -C /opt/python/pypy3/

# Compile wheels
for PYBIN in /opt/python/*/bin; do
    ${PYBIN}/pip install -r /io/dev-requirements.txt
    ${PYBIN}/pip wheel /io/ -w wheelhouse/
done

# Bundle external shared libraries into the wheels
for whl in wheelhouse/*.whl; do
    auditwheel repair $whl -w /io/wheelhouse/
done

# Install packages and test
for PYBIN in /opt/python/*/bin/; do
    ${PYBIN}/pip install python-manylinux-demo --no-index -f /io/wheelhouse
    (cd /io; ${PYBIN}/nosetests pymanylinuxdemo)
done
