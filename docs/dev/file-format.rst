..
   Disable word wrapping while editing.

CCR - CamCoder Recording
========================

File format documentation
--------------------------

Format versions
~~~~~~~~~~~~~~~

================ ==============
Camcoder Version Format version
================ ==============
0.1b - 0.9b      ``00 00``
================ ==============

Overall info
~~~~~~~~~~~~

In any given file, there should be at least three sections:

#. Header
#. Initialiser Frame
#. Delimeter Frame

Different versions and implementations may add new types of sections and should have at least these three

Section
~~~~~~~

Any given section is identified with it's universal Section ID and it's size in bytes. Section ID (sID) is writte as 1 byte unsigned integer, and Section Size (sSZ) is written as 4 byte unsigned integer and does not count itself and sID.
As of 0.1b, there are three types of sections:

#. Header (sID = 0x00)
#. Frames (sID = 0x01+)

Example of section, with sID = 0xFF, sSZ = 4, filled with 0s:

::

   FF 00 00 00 04 00 00 00 00

==== ===============
Name Data
==== ===============
sID  ``FF``
sSZ  ``00 00 00 04``
sDT  ``00 00 00 00``
==== ===============

Section: Header
~~~~~~~~~~~~~~~

sID = 0x00

Identifies CCR version and validity

======= ==============
Size    Data
======= ==============
4 bytes literal "CCRF"
2 bytes format version
======= ==============

Example:

==== =====================
Name Data
==== =====================
sID  ``00``
sSZ  ``00 00 00 06``
sDT  ``43 43 52 46 00 00``
==== =====================

Sections: Frames
~~~~~~~~~~~~~~~~

sID = 0x01 - 0x08

See frames.rst