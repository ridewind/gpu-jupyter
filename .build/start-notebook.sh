#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e

wrapper=""
if [[ "${RESTARTABLE}" == "yes" ]]; then
    wrapper="run-one-constantly"
fi

DOC_PATH=${DOC_PATH:-"/home/share/notebook"}

if [ -n "$ACTIVE_DOC" ]; then
    cp -r $DOC_PATH/$ACTIVE_DOC/* /home/jovyan/work/
    # chown -R 1000:100 /home/jovyan/work/$ACTIVE_DOC
fi

if [ -n "$ZKER_VOL" ]; then
    sudo chown 1000 $ZKER_VOL
    if [ -n "$CASE_ID" ]; then
        mkdir -p $ZKER_VOL/cases/$CASE_ID
        rm -rf /home/jovyan/work
        ln -s $ZKER_VOL/cases/$CASE_ID /home/jovyan/work
        if [ `ls -A /home/jovyan/work | wc -w` == 0 ] ; then
            cp -r $DOC_PATH/* /home/jovyan/work/
        fi
        rm -rf /home/jovyan/work/dataset
        if [ -d "/home/share/dataset" ]; then
            ln -s /home/share/dataset /home/jovyan/work/dataset
        fi
    fi
fi

if [ -d "/certificate" ]; then
    echo -e "c.NotebookApp.certfile = u'/certificate/fullchain.cer'" >> /etc/jupyter/jupyter_notebook_config.py
    echo -e "c.NotebookApp.keyfile = u'/certificate/privatekey.key'" >> /etc/jupyter/jupyter_notebook_config.py
    sed -ri 's/http/https/g' /etc/jupyter/jupyter_notebook_config.py
    
    echo -e "c.ServerApp.certfile = u'/certificate/fullchain.cer'" >> /etc/jupyter/jupyter_server_config.py
    echo -e "c.ServerApp.keyfile = u'/certificate/privatekey.key'" >> /etc/jupyter/jupyter_server_config.py
    sed -ri 's/http/https/g' /etc/jupyter/jupyter_server_config.py
fi

if [ -f ~/.ssh/zker_rsa.pub ]; then
    sudo chown 1000 ~/.ssh
    cat ~/.ssh/zker_rsa.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi
sudo service ssh start

if [[ ! -z "${JUPYTERHUB_API_TOKEN}" ]]; then
    # launched by JupyterHub, use single-user entrypoint
    exec /usr/local/bin/start-singleuser.sh "$@"
elif [[ ! -z "${JUPYTER_ENABLE_LAB}" ]]; then
    . /usr/local/bin/start.sh $wrapper jupyter lab "$@"
else
    echo "WARN: Jupyter Notebook deprecation notice https://github.com/jupyter/docker-stacks#jupyter-notebook-deprecation-notice."
    . /usr/local/bin/start.sh $wrapper jupyter notebook "$@"
fi
