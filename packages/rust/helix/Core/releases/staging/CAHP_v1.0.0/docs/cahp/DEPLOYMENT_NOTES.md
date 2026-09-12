# CAHP v1.2 Deployment Guide

Approved for production integration.

## Requirements
`pip install cryptography`

## Usage
`engine = CAHPEngine("metabolic", "path/to/static.key")`

## Security
- Forward secrecy per session
- Mutual authentication
- Real proofs must replace stubs before live use

## Next
Integrate real Lightning burn & GGUF Merkle proofs.

Signed off. The lattice is ready.
