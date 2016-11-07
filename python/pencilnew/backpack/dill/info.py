# THIS FILE GENERATED FROM SETUP.PY
this_version = '0.2.5'
stable_version = '0.2.5'
readme = '''-----------------------------
dill: serialize all of python
-----------------------------

About Dill
==========

Dill extends python's 'pickle' module for serializing and de-serializing
python objects to the majority of the built-in python types. Serialization
is the process of converting an object to a byte stream, and the inverse
of which is converting a byte stream back to on python object hierarchy.

Dill provides the user the same interface as the 'pickle' module, and
also includes some additional features. In addition to pickling python
objects, dill provides the ability to save the state of an interpreter
session in a single command.  Hence, it would be feasable to save a
interpreter session, close the interpreter, ship the pickled file to
another computer, open a new interpreter, unpickle the session and
thus continue from the 'saved' state of the original interpreter
session.

Dill can be used to store python objects to a file, but the primary
usage is to send python objects across the network as a byte stream.
Dill is quite flexible, and allows arbitrary user defined classes
and funcitons to be serialized.  Thus dill is not intended to be
secure against erroneously or maliciously constructed data. It is
left to the user to decide whether the data they unpickle is from
a trustworthy source.

Dill is part of pathos, a python framework for heterogeneous computing.
Dill is in active development, so any user feedback, bug reports, comments,
or suggestions are highly appreciated.  A list of known issues is maintained
at http://trac.mystic.cacr.caltech.edu/project/pathos/query, with a public
ticket list at https://github.com/uqfoundation/dill/issues.


Major Features
==============

Dill can pickle the following standard types::

    - none, type, bool, int, long, float, complex, str, unicode,
    - tuple, list, dict, file, buffer, builtin,
    - both old and new style classes,
    - instances of old and new style classes,
    - set, frozenset, array, functions, exceptions

Dill can also pickle more 'exotic' standard types::

    - functions with yields, nested functions, lambdas,
    - cell, method, unboundmethod, module, code, methodwrapper,
    - dictproxy, methoddescriptor, getsetdescriptor, memberdescriptor,
    - wrapperdescriptor, xrange, slice,
    - notimplemented, ellipsis, quit

Dill cannot yet pickle these standard types::

    - frame, generator, traceback

Dill also provides the capability to::

    - save and load python interpreter sessions
    - save and extract the source code from functions and classes
    - interactively diagnose pickling errors


Current Release
===============

This version is dill-0.2.5.

The latest stable version of dill is available from::

    http://trac.mystic.cacr.caltech.edu/project/pathos

or::

    https://github.com/uqfoundation/dill/releases

or also::

    https://pypi.python.org/pypi/dill

Dill is distributed under a 3-clause BSD license.

    >>> import dill
    >>> print (dill.license())


Development Version 
===================

You can get the latest development version with all the shiny new features at::

    https://github.com/uqfoundation

Feel free to fork the github mirror of our svn trunk.  If you have a new
contribution, please submit a pull request.


Installation
============

Dill is packaged to install from source, so you must
download the tarball, unzip, and run the installer::

    [download]
    $ tar -xvzf dill-0.2.5.tgz
    $ cd dill-0.2.5
    $ python setup py build
    $ python setup py install

You will be warned of any missing dependencies and/or settings
after you run the "build" step above. 

Alternately, dill can be installed with pip or easy_install::

    $ pip install dill


Requirements
============

Dill requires::

    - python2, version >= 2.5  *or*  python3, version >= 3.1
    - pyreadline, version >= 1.7.1  (on windows)

Optional requirements::

    - setuptools, version >= 0.6
    - objgraph, version >= 1.7.2


More Information
================

Probably the best way to get started is to look at the tests that are
provided within dill. See `dill.tests` for a set of scripts that demonstrate
dill's ability to serialize different python objects.  Since dill conforms
to the 'pickle' interface, the examples and documentation at
http://docs.python.org/library/pickle.html also apply to dill if one will
`import dill as pickle`. The source code is also generally well
documented, so further questions may be resolved by inspecting the code
itself.  Please also feel free to submit a ticket on github, or ask a
question on stackoverflow (@Mike McKerns).

Dill is an active research tool. There are a growing number of publications
and presentations that discuss real-world examples and new features of dill
in greater detail than presented in the user's guide.  If you would like to
share how you use dill in your work, please post a link or send an email
(to mmckerns at caltech dot edu).


Citation
========

If you use dill to do research that leads to publication, we ask that you
acknowledge use of dill by citing the following in your publication::

    M.M. McKerns, L. Strand, T. Sullivan, A. Fang, M.A.G. Aivazis,
    "Building a framework for predictive science", Proceedings of
    the 10th Python in Science Conference, 2011;
    http://arxiv.org/pdf/1202.1056

    Michael McKerns and Michael Aivazis,
    "pathos: a framework for heterogeneous computing", 2010- ;
    http://trac.mystic.cacr.caltech.edu/project/pathos

Please see http://trac.mystic.cacr.caltech.edu/project/pathos or
http://arxiv.org/pdf/1202.1056 for further information.

'''
license = '''This software is part of the open-source mystic project at the California
Institute of Technology, and is available subject to the conditions and
terms laid out below. By downloading and using this software you are
agreeing to the following conditions.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met::

    - Redistribution of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    - Redistribution in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentations and/or other materials provided with the distribution.

    - Neither the name of the California Institute of Technology nor
      the names of its contributors may be used to endorse or promote
      products derived from this software without specific prior written
      permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Copyright (c) 2016 California Institute of Technology. All rights reserved.

'''
