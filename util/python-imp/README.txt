This directory contains a python implementation of some of the lisp code.

The "import.py" script generates an sqlite database out of the accounts and journals.csv
files, in the same way as the lisp implementation does.

The generate_graph.py script generates a description of the value cycle in the dot language.
You can give it an argument that limits the number of transactions it should use, to keep the
graph manageable. It always shows the transactions with the most activity (in terms of money)
first.

As a convenience, the server.py scripts starts a small web server on port 8080 that can be
used to quickly generate graphs in the browser. It allows you to change the number of
transactions displayed, as well as the graphviz algorithm to visualize the graph. This
requires the installation of the 'web.py' module, which is available as 'python-webpy.noarch'
on Fedora or 'python-webpy' in Ubuntu. On OS X, you can use 'easy_install web.py'. If you're
not able to install the packages yourself, you can also run the following command inside the
python-imp directory:

	curl -L https://github.com/webpy/webpy/tarball/master | tar zx --strip-components=1 '*/web'