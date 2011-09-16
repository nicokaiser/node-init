var http = require('http');

var app = http.createServer(function(req, res) {
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.end('Hello World\n');
});

var port = process.env.PORT || 10080;
app.listen(port, function() {
  console.log("Listening on " + port);
});
