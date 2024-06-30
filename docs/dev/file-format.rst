..
   Disable word wrapping while editing.

CCR - CamCoder Recording
========================

File format documentation
--------------------------

Format versions
~~~~~~~~~~~~~~~~~

================ ==============
Camcoder Version Format version
================ ==============
0.1b - 0.9b      ``00 00``
================ ==============

Overall info
~~~~~~~~~~~~

In any given file, there should be at least three sections:

#. Header
#. Initialiser
#. Delimeter Frame

Different versions and implementations may add new types of sections and should have at least these three

Section
~~~~~~~

Any given section is identified with it's universal Section ID and it's size in bytes. Section ID (sID) is writte as 1 byte unsigned integer, and Section Size (sSZ) is written as 4 byte unsigned integer and does not count itself and sID.
As of 0.1b, there are three types of sections:

#. Header (sID = 0x00)
#. Initialiser (sID = 0x01)
#. Frames (sID = 0x02+)

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

Секция: Инициализатор
~~~~~~~~~~~~~~~~~~~~~

sID = 0x01

Данная секция отвечает за инициализацию энтити игрока. Состоит из:

..
   Я НЕНАВИЖУ ГИТХАБ!!
   оригинальная таблица, распарсить можно на https://tablesgenerator.com/text_tables:
   +---------+---------------------------------------+
   | Размер  | Данные                                |
   +---------+---------------------------------------+
   | 2 байта | размер строки модели игрока           |
   +---------+---------------------------------------+
   | ? байт  | модель игрока                         |
   +---------+---------------------------------------+
   | 3 байта | цвет игрока (RGB 0-255)               |
   +---------+---------------------------------------+
   | 3 байта | цвет оружия (RGB 0-255)               |
   +---------+---------------------------------------+
   | 2 байта | количество оружий                     |
   +---------+---------------------------------------+
   | ? байт  | для каждого оружия                    |
   |         +---------+-----------------------------+
   |         | Размер  | Данные                      |
   |         +---------+-----------------------------+
   |         | 1 байт  | тип патронов 1              |
   |         +---------+-----------------------------+
   |         | 2 байта | количество патронов типа 1  |
   |         +---------+-----------------------------+
   |         | 1 байт  | тип патронов 2              |
   |         +---------+-----------------------------+
   |         | 2 байта | количество патронов типа 2  |
   |         +---------+-----------------------------+
   |         | 2 байта | находится в обойме 1        |
   |         +---------+-----------------------------+
   |         | 2 байта | нахожится в обойме 2        |
   |         +---------+-----------------------------+
   |         | 2 байта | размер строки класса оружия |
   |         +---------+-----------------------------+
   |         | ? байт  | класс оружия                |
   +---------+---------+-----------------------------+
   | 2 байта | размер строки класса активного оружия |
   +---------+---------------------------------------+
   | ? байт  | класс активного оружия                |
   +---------+---------------------------------------+

.. raw:: html

   <table style="border-collapse:collapse;border-spacing:0" class="tg"><thead><tr><th style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;font-weight:normal;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">Размер</th><th style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;font-weight:normal;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">Данные</th></tr></thead><tbody><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">размер строки модели игрока</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">? байт</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">модель игрока</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">3 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">цвет игрока (RGB 0-255)</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">3 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">цвет оружия (RGB 0-255)</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">количество оружий</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" rowspan="10">? байт</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">для каждого оружия</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">Размер</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">Данные</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">1 байт</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">тип патронов 1</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">количество патронов типа 1</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">1 байт</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">тип патронов 2</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">количество патронов типа 2</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">находится в обойме 1</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">нахожится в обойме 2</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">размер строки класса оружия</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">? байт</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">класс оружия</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">размер строки класса активного оружия</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">? байт</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">класс активного оружия</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">12 байт<br></td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">позиция игрока</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">3 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">угол игрока</td></tr></tbody></table>

Секция: Фреймы
~~~~~~~~~~~~~~~~~~~~~

sID = 0x02 - 0x08

Данная секция отвечает за воспроизведение действий энтити игрока. 
Фрейм - это единица данных об действии игрока. Больше об этом в соответствующем файле.
