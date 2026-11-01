
#!/usr/bin/env python3

import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit, parse_qs

parser = argparse.ArgumentParser()

parser.add_argument(
    "--port",
    type=int,
    required=True
)

parser.add_argument(
    "--token",
    required=True
)

parser.add_argument(
    "--status-file",
    required=True
)

args = parser.parse_args()

HTML = Path(__file__).with_name(
    "index.html"
).read_bytes()

STATUS = Path(args.status_file)


class Handler(BaseHTTPRequestHandler):

    def authorized(self):
        params = parse_qs(
            urlsplit(self.path).query
        )

        return (
            params.get("token", [None])[0]
            == args.token
        )

    def reply(
        self,
        code,
        data=b"",
        mime="text/plain"
    ):
        self.send_response(code)

        self.send_header(
            "Content-Type",
            mime
        )

        self.send_header(
            "Cache-Control",
            "no-store"
        )

        self.send_header(
            "X-Content-Type-Options",
            "nosniff"
        )

        self.end_headers()

        self.wfile.write(data)

    def do_GET(self):
        path = urlsplit(self.path).path

        if path == "/health":
            return self.reply(
                200,
                b"OK"
            )

        if path == "/" and self.authorized():
            return self.reply(
                200,
                HTML,
                "text/html; charset=utf-8"
            )


        if path == "/result" and self.authorized():
            if STATUS.exists():
                return self.reply(
                    200,
                    STATUS.read_bytes(),
                    "application/json"
                )

            return self.reply(
                200,
                b'{"state":"waiting"}',
                "application/json"
            )

        return self.reply(404)

    def do_POST(self):
        path = urlsplit(self.path).path

        if (
            path != "/status"
            or not self.authorized()
        ):
            return self.reply(403)

        try:
            length = int(
                self.headers.get(
                    "Content-Length",
                    "0"
                )
            )

            if not 0 < length <= 4096:
                return self.reply(400)

            data = json.loads(
                self.rfile.read(length)
            )

            state = data.get("state")

            if state not in (
                "running",
                "registered",
                "error"
            ):
                return self.reply(400)

            message = str(
                data.get("message", "")
            )[:1000]

            STATUS.write_text(
                json.dumps({
                    "state": state,
                    "message": message
                }),
                encoding="utf-8"
            )

            return self.reply(
                200,
                b"OK"
            )

        except (
            ValueError,
            TypeError,
            UnicodeDecodeError
        ):
            return self.reply(400)

    def log_message(self, fmt, *values):
        print(
            fmt % values,
            flush=True
        )


server = ThreadingHTTPServer(
    ("0.0.0.0", args.port),
    Handler
)

print(
    f"Bootstrap server ready on port {args.port}",
    flush=True
)

server.serve_forever()
