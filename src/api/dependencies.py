"""Authentication and authorization dependencies."""

import base64
import binascii
import hashlib
import hmac
import json
import time
from typing import Optional, TypedDict

from fastapi import Depends, HTTPException, Request, status

from src.config.settings import Settings, get_settings

SESSION_COOKIE_NAME = "fleet_route_session"
ALLOWED_ROLES = {"admin", "dispatcher", "viewer"}


class CurrentUser(TypedDict):
    email: str
    role: str


def get_auth_configuration() -> tuple[Settings, str, str]:
    """Return configured login credentials and signing secret, failing closed."""
    settings = get_settings()
    password = settings.auth_password.get_secret_value() if settings.auth_password else None
    secret = settings.auth_secret_key.get_secret_value() if settings.auth_secret_key else None

    if not settings.auth_email or not password or not secret:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication is not configured. Set AUTH_EMAIL, AUTH_PASSWORD, and AUTH_SECRET_KEY.",
        )
    if len(password) < 12 or len(secret) < 32 or settings.auth_role not in ALLOWED_ROLES:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication configuration is invalid.",
        )
    return settings, password, secret


def verify_request_origin(request: Request) -> None:
    """Reject browser requests from origins not allowed by the CORS configuration."""
    origin = request.headers.get("origin")
    if origin and origin not in get_settings().cors_origins:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Origin is not allowed.")


def _encode_segment(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode("ascii")


def _decode_segment(value: str) -> bytes:
    return base64.urlsafe_b64decode(value + "=" * (-len(value) % 4))


def create_session_token(
    email: str,
    role: str,
    secret: str,
    ttl_seconds: int,
) -> str:
    """Create a compact HMAC-signed session token."""
    payload = {
        "sub": email,
        "role": role,
        "exp": int(time.time()) + ttl_seconds,
    }
    encoded_payload = _encode_segment(
        json.dumps(payload, separators=(",", ":"), sort_keys=True).encode("utf-8")
    )
    signature = hmac.new(
        secret.encode("utf-8"),
        encoded_payload.encode("ascii"),
        hashlib.sha256,
    ).digest()
    return f"{encoded_payload}.{_encode_segment(signature)}"


def decode_session_token(token: str, secret: str) -> Optional[dict]:
    """Verify a session token and return its claims, or None if invalid."""
    try:
        encoded_payload, encoded_signature = token.split(".", 1)
        expected_signature = _encode_segment(
            hmac.new(
                secret.encode("utf-8"),
                encoded_payload.encode("ascii"),
                hashlib.sha256,
            ).digest()
        )
        if not hmac.compare_digest(encoded_signature, expected_signature):
            return None

        payload = json.loads(_decode_segment(encoded_payload))
    except (ValueError, TypeError, UnicodeError, binascii.Error, json.JSONDecodeError):
        return None

    if not isinstance(payload, dict) or type(payload.get("exp")) is not int:
        return None
    if payload["exp"] <= int(time.time()):
        return None
    return payload


def get_current_user(request: Request) -> CurrentUser:
    """Authenticate a request using its signed HttpOnly session cookie."""
    verify_request_origin(request)
    settings, _, secret = get_auth_configuration()
    token = request.cookies.get(SESSION_COOKIE_NAME)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sign in to continue.",
        )

    claims = decode_session_token(token, secret)
    email = claims.get("sub") if claims else None
    role = claims.get("role") if claims else None
    if (
        not isinstance(email, str)
        or not isinstance(role, str)
        or email.casefold() != settings.auth_email.strip().casefold()
        or role != settings.auth_role
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Session is invalid or expired. Sign in again.",
        )
    return {"email": settings.auth_email, "role": role}


def require_roles(*allowed_roles: str):
    """Create a dependency that requires authentication and one of the given roles."""
    def authorize(user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
        if user["role"] not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not authorized to perform this action.",
            )
        return user

    return authorize
