# Installation Guide

## Requirements

- **Python:** 3.10, 3.11, or 3.12
- **Operating Systems:** Linux, macOS, Windows
- **Architecture:** x86_64 or ARM64 (Apple Silicon)

## Installation Methods

### 1. pip (Recommended)

```bash
# Install latest stable release
pip install nautilus_trader

# Install with specific extras
pip install nautilus_trader[redis]    # Redis cache support
pip install nautilus_trader[docker]   # Docker utilities
```

### 2. From Source

For development or latest features:

```bash
# Clone repository
git clone https://github.com/nautechsystems/nautilus_trader.git
cd nautilus_trader

# Install in development mode
pip install -e .

# Or build with Poetry
poetry install
```

### 3. Docker

```bash
# Pull official image
docker pull ghcr.io/nautechsystems/nautilus_trader:latest

# Run with your strategy
docker run -v $(pwd):/app ghcr.io/nautechsystems/nautilus_trader python /app/run_strategy.py
```

## Platform-Specific Notes

### macOS (Apple Silicon)

```bash
# Ensure Rosetta is not being used
python3 -c "import platform; print(platform.machine())"
# Should print: arm64

# Install
pip install nautilus_trader
```

### Linux

```bash
# Install system dependencies (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y build-essential python3-dev

# Install
pip install nautilus_trader
```

### Windows

```bash
# Use Python from python.org (not Windows Store)
# Install Visual C++ Build Tools if needed

pip install nautilus_trader
```

## Optional Dependencies

### Redis (for Live Trading)

Required for state persistence in live trading.

```bash
# Install Redis
# macOS
brew install redis

# Ubuntu/Debian
sudo apt-get install redis-server

# Start Redis
redis-server

# Install Python Redis support
pip install nautilus_trader[redis]
```

### uvloop (Linux/macOS)

High-performance event loop for live trading.

```bash
pip install uvloop
```

Enable in your code:

```python
import uvloop
uvloop.install()
```

## Precision Modes

NautilusTrader supports two precision modes for numerical calculations.

### Float Mode (Default)

Uses 64-bit floats. Good for most use cases.

```bash
pip install nautilus_trader
```

### Decimal Mode

Uses fixed-point decimals. Maximum precision for financial calculations.

```bash
# Install decimal build (if available)
pip install nautilus_trader-decimal
```

## Verifying Installation

```python
import nautilus_trader
print(nautilus_trader.__version__)

# Test imports
from nautilus_trader.trading import Strategy
from nautilus_trader.backtest.engine import BacktestEngine
from nautilus_trader.model.data import Bar, QuoteTick

print("Installation successful!")
```

## Virtual Environment (Recommended)

```bash
# Create virtual environment
python -m venv venv

# Activate
# Linux/macOS
source venv/bin/activate
# Windows
venv\Scripts\activate

# Install
pip install nautilus_trader

# Deactivate when done
deactivate
```

## Conda Environment

```bash
# Create environment
conda create -n nautilus python=3.11

# Activate
conda activate nautilus

# Install
pip install nautilus_trader
```

## Development Installation

For contributing or modifying NautilusTrader:

```bash
# Clone
git clone https://github.com/nautechsystems/nautilus_trader.git
cd nautilus_trader

# Install Poetry
pip install poetry

# Install dependencies
poetry install --all-extras

# Activate shell
poetry shell

# Run tests
pytest tests/
```

## Common Issues

### Build Errors

```bash
# Ensure build tools are installed
# macOS
xcode-select --install

# Linux
sudo apt-get install build-essential python3-dev

# Windows
# Install Visual C++ Build Tools from Microsoft
```

### Import Errors

```bash
# Verify Python version
python --version  # Should be 3.10, 3.11, or 3.12

# Verify installation
pip show nautilus_trader
```

### Redis Connection Errors

```bash
# Check Redis is running
redis-cli ping  # Should return PONG

# Check connection settings in config
```

## Upgrading

```bash
# Upgrade to latest
pip install --upgrade nautilus_trader

# Upgrade to specific version
pip install nautilus_trader==2.0.0
```

## Uninstalling

```bash
pip uninstall nautilus_trader
```

## Next Steps

- **Architecture overview:** Read `architecture.md`
- **Build your first strategy:** Read `strategy-development.md`
- **Run a backtest:** Read `backtesting.md`

## Additional Resources

- **Installation Docs:** https://nautilustrader.io/docs/latest/getting_started/installation/
- **GitHub Releases:** https://github.com/nautechsystems/nautilus_trader/releases
- **PyPI:** https://pypi.org/project/nautilus-trader/
