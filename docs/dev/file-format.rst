..
   Выключи перенос строк при редактировании.

CCR - CamCoder Recording
========================

Документация формата файла
--------------------------

Версии протоколов
~~~~~~~~~~~~~~~~~

=============== ==============
Версия Camcoder Версия формата
=============== ==============
0.1b            ``00 00``
=============== ==============

Общий вид
~~~~~~~~~

В каждом CCR файле есть как минимум три секции:

#. Заголовок
#. Инициализатор
#. Фрейм

Разные имплементации и версии формата могут добавлять новые секции, но данные три обязательны для любой имплементации.

Секция
~~~~~~

Каждая секция сопровождается её идентификационным номером (sID) и размером в байтах. sID должен занимать ровно 1 байт. Его размер не включается к остальному размеру секции. Размер секции должен занимать ровно 4 байта. На момент версии 0.1b существует три вида секций:

#. Заголовок (sID = 0x00)
#. Инициализатор (sID = 0x01)
#. Фреймы (sID = 0x02) Пример секции размером 4 байта и sID равным 0xFF, заполненной нулями:

::

   FF 00 00 00 04 00 00 00 00

и в "распакованном" виде:

=== ===============
Имя Данные
=== ===============
sID ``FF``
sSZ ``00 00 00 04``
sDT ``00 00 00 00``
=== ===============

Секция: Заголовок
~~~~~~~~~~~~~~~~~

sID = 0x00

Данная секция отвечает за идентификацию CCR файла и его версии протокола. На момент 0.1b занимает 6 байт: Состоит из:

======= ==============
Размер  Данные
======= ==============
4 байта строка "CCRF"
2 байта версия формата
======= ==============

Пример:

=== =====================
Имя Данные
=== =====================
sID ``00``
sSZ ``00 00 00 06``
sDT ``43 43 52 46 00 00``
=== =====================

Секция: Инициализатор
~~~~~~~~~~~~~~~~~~~~~

sID = 0x01

Данная секция отвечает за инициализацию энтити игрока. Состоит из:

..
   Я НЕНАВИЖУ ГИТХАБ!!
   оригинальная таблица, распарсить можно на https://tablesgeenrator.com/text_tables:
   +---------+---------------------------------------+
   | Размер  | Данные                                |
   +=========+=======================================+
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

   <table style="border-collapse:collapse;border-spacing:0;margin:0px auto" class="tg"><thead><tr><th style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;font-weight:normal;overflow:hidden;padding:10px 5px;position:-webkit-sticky;position:sticky;text-align:left;top:-1px;vertical-align:top;will-change:transform;word-break:normal">Размер</th><th style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;font-weight:normal;overflow:hidden;padding:10px 5px;position:-webkit-sticky;position:sticky;text-align:left;top:-1px;vertical-align:top;will-change:transform;word-break:normal" colspan="2">Данные</th></tr></thead><tbody><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">размер строки модели игрока</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">? байт</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">модель игрока</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">3 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">цвет игрока (RGB 0-255)</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">3 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">цвет оружия (RGB 0-255)</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">количество оружий</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" rowspan="10">? байт</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">для каждого оружия</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">Размер</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">Данные</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">1 байт</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">тип патронов 1</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">количество патронов типа 1</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">1 байт</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">тип патронов 2</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">количество патронов типа 2</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта<br></td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">находится в обойме 1</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">нахожится в обойме 2</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">размер строки класса оружия</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">? байт<br></td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">класс оружия</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">2 байта</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">размер строки класса активного оружия</td></tr><tr><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal">? байт</td><td style="border-color:inherit;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;overflow:hidden;padding:10px 5px;text-align:left;vertical-align:top;word-break:normal" colspan="2">класс активного оружия<br></td></tr></tbody></table>

Секция: Фреймы
~~~~~~~~~~~~~~~~~~~~~

sID = 0x02

Данная секция отвечает за воспроизведение действий энтити игрока. 
Фрейм - это единица данных об действии игрока. Больше об этом в соответствующем файле.
Состоит из:

======= =============
Размер  Данные
======= =============
1 байт  вид фрейма
4 байта размер фрейма
? байт  данные фрейма
======= =============
