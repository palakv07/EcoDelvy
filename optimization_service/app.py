"""Health endpoint and lifecycle for the standalone optimization worker."""

import asyncio
import logging
from pathlib import Path
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI

from src.config import setup_logging

from .worker import dispatch_jobs, worker_configuration

env_path = Path(__file__).resolve().parent.parent / ".env"
if env_path.exists():
    load_dotenv(env_path)
else:
    load_dotenv()
setup_logging()
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    serverpod_url, _, poll_interval = worker_configuration()
    stop = asyncio.Event()
    dispatcher = asyncio.create_task(dispatch_jobs(stop, poll_interval))
    app.state.serverpod_url = serverpod_url
    app.state.poll_interval = poll_interval
    logger.info("Optimization worker started.")
    try:
        yield
    finally:
        stop.set()
        await dispatcher
        logger.info("Optimization worker stopped.")


app = FastAPI(
    title="EcoDelvy Optimization Worker",
    description="Private worker that runs the existing OR-Tools and Gurobi solvers.",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ready"}
