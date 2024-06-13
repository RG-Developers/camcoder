Camcoder Interface
===================

Документация интерфейса
-----------------------

Обычно, вам не нужно будет использовать версии формата вручную.
За это вместо вас отвечает интерфейс. Так-же он предоставляет возможность лёгкой
клиент-серверной коммуникации вместо ручной имплементации.

Файл интерфейса - ``camcoder/format/ccr_interface.lua``

	CLIENT REALM
	``ccr.Request(string request, table data, function(req, data, reply) callback)``
	Отправляет на сервер "сырой" запрос.

	CLIENT REALM
	``ccr.StartRecord(function ok_callback, function(error) fail_callback)``
	Отправляет на сервер запрос о начале записи.

	CLIENT REALM
	``ccr.StopRecord(function ok_callback, function(error) fail_callback)``
	Отправляет на сервер запрос об остановке записи.

	CLIENT REALM
	``ccr.Save(string filename, function ok_callback, function(error) fail_callback)``
	Отправляет на сервер запрос о сохранении оконченной записи.

	CLIENT REALM
	``ccr.Play(table records, function ok_callback, function(error) fail_callback)``
	Отправляет на сервер запрос о начале воспроизведения

	CLIENT REALM
	``ccr.Stop(function ok_callback, function(error) fail_callback)``
	Отправляет на сервер запрос об остановке воспроизведения.

	CLIENT REALM
	``ccr.ListRecords(function callback)``
	Получает список записей с сервера.

	CLIENT REALM
	``ccr.Fetch(string filename, function callback``
	Скачивает запись с сервера в локальное хранилище.

	SERVER REALM
	``ccr.Reply(Player who, string request, table data)``
	Отправляет на клиент "сырой" ответ.

	SHARED REALM
	``ccr.FromRAW(string raw)``
	Открывает данную строку как ccr_file указанной в заголовке версии.