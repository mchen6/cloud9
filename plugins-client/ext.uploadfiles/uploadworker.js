var connections = new Array();
connections.length = 0;

var BYTES_PER_CHUNK = 256 * 1024; // 256k chunk sizes.

self.onmessage = function (e) {
    var data = e.data;
    if (!data.cmd) {
        self.postMessage({value: "No cmd specified"});
    }
    else {
        switch (data.cmd) {
            case 'connect':
                var filepath = data.path + "/" + data.file.name;
                if (data._csrf)
                    self._csrf = data._csrf;

                if (!(filepath in connections)) {
                    connections[filepath] = {};
                    connections.length++;

                    if (connections.length > 1) {
                        self.postMessage({value: "Error: Too many connections"});
                        return;
                    }

                    self.canceled = false;

                    self.postMessage({value: data.id + " has connected on port #" + connections.length + "."});
                    self.postMessage({value: "Starting...", filename: data.file.name});

                    // Processing ...
                    var reader = new FileReaderSync();
                    var file = reader.readAsArrayBuffer(data.file);

                    var blob = file;
                    var blobsize = blob.byteLength;

                    var start = 0;
                    var end = BYTES_PER_CHUNK;
                    if (end > blobsize)
                        end = blobsize;

                    function next(error){
                        if (error) {
                            self.postMessage({type: "paused", error: error, filepath: filepath});
                            return;
                        }

                        var chunk = blob.slice(start, end);

                        self.uploadChunk(chunk, filepath, start, end, blobsize, next);

                        start = end;
                        end = start + BYTES_PER_CHUNK;
                        if (end > blobsize)
                            end = blobsize;
                    }
                    connections[filepath].next = next;

                    next();
                }
                else {
                    connections[filepath].next();
                }

                break;
            case 'cancelall':
                self.canceled = true;
                for (var filepath in connections) {
                    if (connections.hasOwnProperty(filepath)) {
                        connections[filepath].http.abort();
                        delete connections[filepath];
                        connections.length--;
                        self.postMessage({type: "complete"});
                    }
                }
                self.postMessage({type: "canceled"});
                break;
            default:
                self.postMessage({value: "unknown cmd"});
        }
    }
};

// uploading file in chunks
self.uploadChunk = function(chunk, filepath, start, end, blobsize, next) {
    var http = new XMLHttpRequest();
    var url = filepath;
    if (self._csrf)
        url += (url.indexOf("?") > -1 ? "&" : "?") + "_csrf=" + self._csrf;
    http.open("PUT", url, true);
    http.onreadystatechange = function(){
        if (http.readyState != 4 || self.canceled)
            return;

        if (end == blobsize) {
            // file upload complete
            delete connections[filepath];
            connections.length--;
            return self.postMessage({type: "complete"});
        }

        self.postMessage({type: "progress", value: end/blobsize});

        next(http.status < 200 || http.status > 299 ? http.status : 0);
    };
    /*
    http.setRequestHeader("Cache-Control", "no-cache");
    http.setRequestHeader("X-File-Name", filename);
    http.setRequestHeader("X-File-Size", filesize);
    http.setRequestHeader("Content-Type", "application/octet-stream");
    */
    http.setRequestHeader("x-file-mode", start == 0? "create" : "append");
    http.setRequestHeader("x-file-size", blobsize);
    http.send(chunk);
    connections[filepath].http = http;
};

if (!ArrayBuffer.prototype.slice) {
    ArrayBuffer.prototype.slice = function (start, end) {
        var that = new Uint8Array(this);
        if (end === undefined)
            end = that.length;
        var result = new ArrayBuffer(end - start);
        var resultArray = new Uint8Array(result);
        for (var i = 0; i < resultArray.length; i++)
            resultArray[i] = that[i + start];
        return result;
    };
}
