"""Data models for CVRPTW solver."""

from .domain import (
    Location,
    TimeWindow,
    Customer,
    Vehicle,
    Depot,
    ProblemData,
    RouteStop,
    Route,
    Solution,
)

__all__ = [
    # Domain models
    "Location",
    "TimeWindow",
    "Customer",
    "Vehicle",
    "Depot",
    "ProblemData",
    "RouteStop",
    "Route",
    "Solution",
]
