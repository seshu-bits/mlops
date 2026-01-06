"""
Pytest configuration for test suite.
Sets up environment variables before any test collection.
"""
import os
import sys
from pathlib import Path

# Add parent directory to path for imports
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

# Set TESTING environment variable before any imports
# This prevents api_server from loading actual model files during test collection
os.environ["TESTING"] = "1"
