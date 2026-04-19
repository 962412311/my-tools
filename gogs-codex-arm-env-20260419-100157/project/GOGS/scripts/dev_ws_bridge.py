#!/usr/bin/env python3

from __future__ import annotations

import argparse
import base64
import hashlib
import os
import select
import socket
import sys
import threading


BUFFER_SIZE = 65536
MAX_HEADER_BYTES = 65536
WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"


def recv_http_headers(sock: socket.socket) -> bytes:
    data = b""
    while b"\r\n\r\n" not in data:
        chunk = sock.recv(4096)
        if not chunk:
            break
        data += chunk
        if len(data) > MAX_HEADER_BYTES:
            raise ValueError("header too large")
    return data


def parse_http_request(data: bytes) -> tuple[str, dict[str, str]]:
    header_text = data.decode("latin1")
    lines = header_text.split("\r\n")
    request_line = lines[0]
    headers = {}
    for line in lines[1:]:
        if not line:
            break
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        headers[key.strip().lower()] = value.strip()
    return request_line, headers


def compute_accept(key: str) -> str:
    digest = hashlib.sha1(f"{key}{WS_GUID}".encode("utf-8")).digest()
    return base64.b64encode(digest).decode("ascii")


def close_socket(sock: socket.socket | None) -> None:
    if sock is None:
        return
    try:
        sock.shutdown(socket.SHUT_RDWR)
    except OSError:
        pass
    try:
        sock.close()
    except OSError:
        pass


def relay_websocket_stream(client: socket.socket, backend: socket.socket) -> None:
    sockets = (client, backend)
    while True:
        readable, _, errored = select.select(sockets, (), sockets, 30)
        if errored:
            break
        if not readable:
            continue
        for source in readable:
            target = backend if source is client else client
            try:
                chunk = source.recv(BUFFER_SIZE)
            except OSError:
                return
            if not chunk:
                return
            try:
                target.sendall(chunk)
            except OSError:
                return


def send_simple_response(client: socket.socket, status: str, message: str) -> None:
    body = message.encode("utf-8")
    response = (
        f"HTTP/1.1 {status}\r\n"
        "Content-Type: text/plain; charset=utf-8\r\n"
        f"Content-Length: {len(body)}\r\n"
        "Connection: close\r\n\r\n"
    ).encode("utf-8") + body
    client.sendall(response)


def handle_client(client: socket.socket, address: tuple[str, int], args: argparse.Namespace) -> None:
    backend = None
    try:
        request_bytes = recv_http_headers(client)
        _, request_headers = parse_http_request(request_bytes)
        client_key = request_headers.get("sec-websocket-key")
        upgrade = request_headers.get("upgrade", "").lower()
        if not client_key or upgrade != "websocket":
            send_simple_response(client, "400 Bad Request", "Expected WebSocket upgrade request")
            return

        backend = socket.create_connection((args.backend_host, args.backend_port), timeout=10)
        backend.settimeout(None)

        backend_key = base64.b64encode(os.urandom(16)).decode("ascii")
        backend_request = (
            f"GET {args.backend_path} HTTP/1.1\r\n"
            f"Host: {args.backend_host}:{args.backend_port}\r\n"
            "Upgrade: websocket\r\n"
            "Connection: Upgrade\r\n"
            f"Sec-WebSocket-Key: {backend_key}\r\n"
            "Sec-WebSocket-Version: 13\r\n\r\n"
        ).encode("utf-8")
        backend.sendall(backend_request)

        backend_response = recv_http_headers(backend)
        status_line, _ = parse_http_request(backend_response)
        if "101" not in status_line:
            send_simple_response(client, "502 Bad Gateway", "Backend WebSocket upgrade failed")
            return

        client_response = (
            "HTTP/1.1 101 Switching Protocols\r\n"
            "Upgrade: websocket\r\n"
            "Connection: Upgrade\r\n"
            f"Sec-WebSocket-Accept: {compute_accept(client_key)}\r\n\r\n"
        ).encode("utf-8")
        client.sendall(client_response)

        relay_websocket_stream(client, backend)
    except Exception as exc:
        sys.stdout.write(f"{address[0]}:{address[1]} bridge error: {exc}\n")
        sys.stdout.flush()
    finally:
        close_socket(backend)
        close_socket(client)


def main() -> None:
    parser = argparse.ArgumentParser(description="Lightweight local WebSocket bridge for remote backend streams.")
    parser.add_argument("--listen-host", default="127.0.0.1")
    parser.add_argument("--listen-port", type=int, default=18081)
    parser.add_argument("--backend-host", default="192.168.1.211")
    parser.add_argument("--backend-port", type=int, default=12345)
    parser.add_argument("--backend-path", default="/")
    args = parser.parse_args()

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((args.listen_host, args.listen_port))
    server.listen()

    print(
        f"WS bridge listening on ws://{args.listen_host}:{args.listen_port}"
        f" -> ws://{args.backend_host}:{args.backend_port}{args.backend_path}",
        flush=True,
    )

    try:
        while True:
            client, address = server.accept()
            worker = threading.Thread(target=handle_client, args=(client, address, args), daemon=True)
            worker.start()
    except KeyboardInterrupt:
        pass
    finally:
        server.close()


if __name__ == "__main__":
    main()
