"""Login and session endpoints."""

import hmac

from fastapi import APIRouter, Depends, HTTPException, Request, Response, status

from src.config.settings import get_settings
from src.models.api import LoginRequest, UserResponse
from .dependencies import (
    SESSION_COOKIE_NAME,
    CurrentUser,
    create_session_token,
    get_auth_configuration,
    get_current_user,
    verify_request_origin,
)

router = APIRouter()


@router.post("/login", response_model=UserResponse)
def login(credentials: LoginRequest, request: Request, response: Response) -> UserResponse:
    """Authenticate the configured account and issue a secure session cookie."""
    verify_request_origin(request)
    settings, expected_password, secret = get_auth_configuration()
    email_matches = hmac.compare_digest(
        credentials.email.strip().casefold().encode("utf-8"),
        settings.auth_email.strip().casefold().encode("utf-8"),
    )
    password_matches = hmac.compare_digest(
        credentials.password.encode("utf-8"),
        expected_password.encode("utf-8"),
    )
    if not (email_matches and password_matches):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password.",
        )

    response.set_cookie(
        key=SESSION_COOKIE_NAME,
        value=create_session_token(
            settings.auth_email,
            settings.auth_role,
            secret,
            settings.auth_token_ttl_minutes * 60,
        ),
        max_age=settings.auth_token_ttl_minutes * 60,
        httponly=True,
        secure=settings.auth_cookie_secure,
        samesite="lax",
        path="/",
    )
    return UserResponse(email=settings.auth_email, role=settings.auth_role)


@router.get("/me", response_model=UserResponse)
def current_user(user: CurrentUser = Depends(get_current_user)) -> UserResponse:
    """Return the authenticated account."""
    return UserResponse(**user)


@router.post("/logout")
def logout(request: Request, response: Response) -> dict[str, bool]:
    """Clear the current browser session."""
    verify_request_origin(request)
    response.delete_cookie(
        key=SESSION_COOKIE_NAME,
        httponly=True,
        secure=get_settings().auth_cookie_secure,
        samesite="lax",
        path="/",
    )
    return {"ok": True}
