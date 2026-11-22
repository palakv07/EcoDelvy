import unittest
from unittest.mock import patch

from fastapi import HTTPException
from pydantic import SecretStr
from starlette.requests import Request

from src.api.dependencies import (
    SESSION_COOKIE_NAME,
    create_session_token,
    decode_session_token,
    get_current_user,
    require_roles,
)
from src.config.settings import Settings


class SessionTokenTests(unittest.TestCase):
    def test_signed_token_round_trip_and_tamper_rejection(self):
        token = create_session_token("demo@fleet.local", "admin", "s" * 32, 60)

        claims = decode_session_token(token, "s" * 32)
        self.assertEqual(claims["sub"], "demo@fleet.local")
        self.assertEqual(claims["role"], "admin")
        self.assertIsNone(decode_session_token(token, "x" * 32))
        self.assertIsNone(decode_session_token(token.rsplit(".", 1)[0] + ".invalid", "s" * 32))

    def test_expired_token_is_rejected(self):
        token = create_session_token("demo@fleet.local", "admin", "s" * 32, 0)
        self.assertIsNone(decode_session_token(token, "s" * 32))

    def test_authenticated_user_and_role_authorization(self):
        settings = Settings(
            auth_email="demo@fleet.local",
            auth_password=SecretStr("FleetDemo!2026"),
            auth_secret_key=SecretStr("s" * 32),
            auth_role="admin",
        )
        token = create_session_token(
            settings.auth_email,
            settings.auth_role,
            settings.auth_secret_key.get_secret_value(),
            60,
        )
        request = Request({
            "type": "http",
            "method": "GET",
            "path": "/auth/me",
            "headers": [(b"cookie", f"{SESSION_COOKIE_NAME}={token}".encode())],
            "query_string": b"",
            "server": ("testserver", 80),
            "client": ("testclient", 1234),
            "scheme": "http",
            "http_version": "1.1",
        })

        with patch("src.api.dependencies.get_settings", return_value=settings):
            user = get_current_user(request)
            self.assertEqual(user["role"], "admin")
            self.assertEqual(require_roles("admin")(user), user)

            with self.assertRaises(HTTPException) as error:
                require_roles("dispatcher")(user)
            self.assertEqual(error.exception.status_code, 403)


if __name__ == "__main__":
    unittest.main()
