Camcoder Interface
===================

Interface documentation
-----------------------

Normally, you will not need to use the format versions manually.
The interface takes care of that for you. It also provides the possibility of easy
client-server communication instead of manual implementation.

The interface file is ``camcoder/format/ccr_interface.lua``.

	CLIENT REALM
	```ccr.Request(string request, table data, function(req, data, reply) callback)``.
	Sends a "raw" request to the server.

	CLIENT REALM
	``ccr.StartRecord(function ok_callback, function(error) fail_callback)``
	Sends a request to the server to start a record.

	CLIENT REALM
	```ccr.StopRecord(function ok_callback, function(error) fail_callback)``
	Sends a request to the server to stop recording.

	CLIENT REALM
	``ccr.Save(string filename, function ok_callback, function(error) fail_callback)``
	Sends a request to the server to save a stopped record.

	CLIENT REALM
	```ccr.Play(table records, function ok_callback, function(error) fail_callback)``
	Sends a request to the server to start playback

	CLIENT REALM
	``ccr.Stop(function ok_callback, function(error) fail_callback)``
	Sends a request to the server to stop playback.

	CLIENT REALM
	``ccr.ListRecords(function callback)``
	Retrieves a list of records from the server.

	CLIENT REALM
	``ccr.Fetch(string filename, function callback)``.
	Downloads a record from the server to local storage.

	CLIENT REALM
	``ccr.FetchFile(string filename, function callback)``.
	Downloads a file relative to data/camcoder from the server to local storage.

	CLIENT REALM
	``ccr.Push(string filename, function callback)``.
	Uploads a record to the server from local storage.

	CLIENT REALM
	``ccr.PushFile(string filename, function callback)``.
	Uploads a file relative to data/camcoder to the server from local storage.

	SERVER REALM
	``ccr.Reply(Player who, string request, table data)``.
	Sends a raw response to the client.

	SHARED REALM
	``ccr.FromRAW(string raw) -> CCRF handle``.
	Opens string as a ccr_file of the version specified in the header.

	SHARED REALM
	``ccr.ReadFromFile(string path) -> CCRF handle``.
	Opens the path as a ccr_file of the version specified in the header, relative to data/camcoder/recordings.