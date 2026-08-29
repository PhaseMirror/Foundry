"""
datasets package init
"""

from binary_fragmentation.datasets.corporate_ownership_graph import (
    load_corporate_ownership_graph,
)
from binary_fragmentation.datasets.public_procurement_graph import (
    load_public_procurement_graph,
)

__all__ = [
    "load_corporate_ownership_graph",
    "load_public_procurement_graph",
]
