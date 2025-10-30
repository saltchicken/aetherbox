from http.server import SimpleHTTPRequestHandler, HTTPServer

PORT = 8001

class WASMRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # Force .wasm files to have correct MIME type
        if self.path.endswith(".wasm"):
            self.send_header("Content-Type", "application/wasm")
        super().end_headers()

httpd = HTTPServer(("localhost", PORT), WASMRequestHandler)
print(f"Serving at http://localhost:{PORT}")
httpd.serve_forever()

