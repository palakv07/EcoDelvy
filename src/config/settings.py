"""Application settings using Pydantic."""

from typing import Optional, List, Annotated, Literal
from pydantic_settings import BaseSettings, NoDecode, SettingsConfigDict
from pydantic import Field, SecretStr, field_validator
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings."""
    
    # API Settings
    app_name: str = Field("Fleet Route Optimizer API", description="Application name")
    api_host: str = Field("127.0.0.1", description="API host")
    api_port: int = Field(8000, description="API port")
    debug: bool = Field(False, description="Debug mode")
    
    # CORS Settings
    cors_origins: Annotated[List[str], NoDecode] = Field(
        ["http://localhost:3000", "http://127.0.0.1:3000"],
        description="Allowed CORS origins"
    )
    
    # Solver Settings
    default_time_limit: int = Field(60, description="Default solver time limit in seconds")
    default_solver: str = Field("ortools", description="Default solver (ortools/gurobi)")
    ortools_vehicle_penalty: float = Field(100000.0, description="OR-Tools vehicle penalty weight")
    gurobi_vehicle_penalty: float = Field(1000.0, description="Gurobi vehicle penalty weight")
    default_distance_weight: float = Field(1.0, description="Default distance weight")
    default_mip_gap: float = Field(0.01, description="Default MIP gap for Gurobi")
    
    # Distance Cache Settings
    distance_cache_db: str = Field("distance_cache.db", description="Distance cache database path")
    osrm_base_url: str = Field("http://router.project-osrm.org", description="OSRM API base URL")
    
    # Logging Settings
    log_level: str = Field("INFO", description="Logging level")
    log_format: str = Field(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        description="Log format string"
    )
    
    # Authentication Settings
    auth_email: str = Field("", description="Configured login email")
    auth_password: Optional[SecretStr] = Field(None, description="Configured login password")
    auth_secret_key: Optional[SecretStr] = Field(None, description="Session signing secret")
    auth_role: Literal["admin", "dispatcher", "viewer"] = Field(
        "admin",
        description="Role assigned to the configured account",
    )
    auth_token_ttl_minutes: int = Field(60, ge=1, le=1440, description="Session lifetime in minutes")
    auth_cookie_secure: bool = Field(False, description="Require HTTPS for the session cookie")
    
    # File paths
    inputs_dir: str = Field("inputs", description="Input files directory")
    results_dir: str = Field("results", description="Results output directory")

    @field_validator("cors_origins", mode="before")
    @classmethod
    def parse_cors_origins(cls, value):
        """Accept CORS origins as a JSON array or comma-separated text."""
        if isinstance(value, str):
            value = value.strip()
            if value.startswith("["):
                import json
                return json.loads(value)
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
