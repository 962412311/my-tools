#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin
from urllib.request import Request, urlopen


HOP_BY_HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
}


class BridgeHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    backend_base = ""

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self):
        self._forward()

    def do_POST(self):
        self._forward()

    def do_PUT(self):
        self._forward()

    def do_DELETE(self):
        self._forward()

    def do_PATCH(self):
        self._forward()

    def _forward(self):
        target_url = urljoin(self.backend_base, self.path)
        body = None
        content_length = int(self.headers.get("Content-Length", "0") or "0")
        if content_length > 0:
            body = self.rfile.read(content_length)

        headers = {}
        for key, value in self.headers.items():
            key_lower = key.lower()
            if key_lower in HOP_BY_HOP_HEADERS or key_lower == "host":
                continue
            headers[key] = value

        request = Request(target_url, data=body, headers=headers, method=self.command)

        try:
            with urlopen(request, timeout=15) as response:
                payload = response.read()
                self.send_response(response.status)
                for key, value in response.headers.items():
                    if key.lower() in HOP_BY_HOP_HEADERS or key.lower() == "content-length":
                        continue
                    self.send_header(key, value)
                self.send_header("Content-Length", str(len(payload)))
                self.end_headers()
                if payload:
                    self.wfile.write(payload)
        except HTTPError as error:
            payload = error.read()
            self.send_response(error.code)
            for key, value in error.headers.items():
                if key.lower() in HOP_BY_HOP_HEADERS or key.lower() == "content-length":
                    continue
                self.send_header(key, value)
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            if payload:
                self.wfile.write(payload)
        except URLError as error:
            payload = json.dumps({"error": str(error.reason)}).encode("utf-8")
            self.send_response(502)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

    def log_message(self, fmt, *args):
        sys.stdout.write(f"{self.address_string()} - - [{self.log_date_time_string()}] {fmt % args}\n")
        sys.stdout.flush()


def main():
    parser = argparse.ArgumentParser(description="Lightweight local bridge for remote backend HTTP APIs.")
    parser.add_argument("--listen-host", default="127.0.0.1")
    parser.add_argument("--listen-port", type=int, default=18080)
    parser.add_argument("--backend-base", default="http://192.168.1.211:8080")
    args = parser.parse_args()

    BridgeHandler.backend_base = args.backend_base.rstrip("/")
    server = ThreadingHTTPServer((args.listen_host, args.listen_port), BridgeHandler)
    print(f"HTTP bridge listening on http://{args.listen_host}:{args.listen_port} -> {BridgeHandler.backend_base}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
