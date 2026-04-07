# Simple static server for WorldClassScholarsSite
from http.server import SimpleHTTPRequestHandler, HTTPServer
import sys
import os

PORT = int(os.environ.get("PORT", 8000))

class CORSRequestHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'x-api-key, Content-Type')
        SimpleHTTPRequestHandler.end_headers(self)

if __name__ == "__main__":
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    httpd = HTTPServer(("0.0.0.0", PORT), CORSRequestHandler)
    print(f"Serving at http://0.0.0.0:{PORT}")
    httpd.serve_forever()
