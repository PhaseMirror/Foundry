from setuptools import setup, find_packages

setup(
    name="multiplicity-crypto-py",
    version="1.0.0",
    packages=find_packages(where="."),
    python_requires=">=3.9",
    description="QKD Hybrid Encryption v1.0.1 — Python interop bridge",
)
