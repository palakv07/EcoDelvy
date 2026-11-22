"""Main application entry point."""

import uvicorn
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .api import router
from .config import setup_logging, get_settings, get_logger

# Setup logging
setup_logging()
logger = get_logger(__name__)

# Get settings
settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    logger.info(f"{settings.app_name} starting up...")
    logger.info(f"Debug mode: {settings.debug}")
    yield
    logger.info(f"{settings.app_name} shutting down...")


# Create FastAPI app
app = FastAPI(
    title=settings.app_name,
    description="Fleet Route Optimizer - API for solving Capacitated Vehicle Routing Problem with Time Windows (CVRPTW) using real-world distances and traffic patterns",
    version="2.0.0",
    lifespan=lifespan,
)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API routes
app.include_router(router, tags=["solver"])


if __name__ == "__main__":
    uvicorn.run(
        "src.app:app",
        host=settings.api_host,
        port=settings.api_port,
        log_level=settings.log_level.lower(),
        reload=settings.debug
    )
