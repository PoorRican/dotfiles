---
name: nautilus-trader-expert
description: Expert guidance for NautilusTrader algorithmic trading platform. Use when users ask about backtesting strategies, live trading deployment, event-driven architecture, or building trading systems with NautilusTrader.
---

# Nautilus Trader Skill

## Instructions

When helping users with NautilusTrader:

1. **Identify the task type** - Determine if the user needs help with strategy development, backtesting, live trading, data handling, or architecture understanding
2. **Read relevant files** - Use the file guide below to read only the necessary documentation files
3. **Provide working code** - Always include complete, runnable code examples following NautilusTrader patterns
4. **Emphasize safety** - For live trading, always recommend thorough backtesting and risk management
5. **Reference official docs** - Point users to official documentation for the latest API details

## Examples

**Example 1: User wants to create a simple moving average crossover strategy**
- Read: `strategy-development.md`, `indicators.md`
- Provide: Complete Strategy class with EMA indicators, proper lifecycle methods, and order submission

**Example 2: User wants to backtest a strategy**
- Read: `backtesting.md`, `data-models.md`
- Provide: BacktestNode configuration, data loading, and results analysis

**Example 3: User asks about the Actor vs Strategy difference**
- Read: `actors.md`, `strategy-development.md`
- Explain: Actor is the base class for non-trading components; Strategy extends Actor with order management

**Example 4: User wants to deploy a strategy live**
- Read: `live-trading.md`, `best-practices.md`
- Provide: TradingNode setup, risk configuration, and deployment checklist

## Overview

NautilusTrader is an open-source, high-performance, production-grade algorithmic trading platform that enables quantitative traders to backtest and deploy automated trading strategies with an event-driven architecture. The platform's core components are written in Rust and Cython for maximum performance while maintaining a Python-native interface.

**Key Features:**
- Event-driven architecture with nanosecond resolution
- Identical code for backtesting and live trading (no reimplementation needed)
- Multi-venue, multi-asset support (crypto, FX, equities, futures, options)
- High-performance core with Rust/Cython binaries and Python bindings

## Official Documentation

- **Main Documentation:** https://nautilustrader.io/docs/latest/
- **GitHub Repository:** https://github.com/nautechsystems/nautilus_trader
- **API Reference:** https://nautilustrader.io/docs/latest/api_reference/

## Skill Structure

This skill is organized into modular sections. Read the relevant file(s) based on the user's needs:

### 📦 [installation.md](installation.md)
**Read when:** User asks about installing, setting up, or configuring NautilusTrader
- Installation methods (pip, from source)
- Platform-specific considerations
- Python version requirements
- Optional dependencies (Redis)
- Precision modes

### 🏗️ [architecture.md](architecture.md)
**Read when:** User needs to understand the system architecture or core components
- NautilusKernel overview
- MessageBus and event-driven patterns
- Cache system
- Core engines (Data, Execution, Risk)
- Portfolio management
- Source code structure

### 📈 [strategy-development.md](strategy-development.md)
**Read when:** User wants to create or modify trading strategies
- Strategy base class and lifecycle
- Event handlers (on_start, on_quote_tick, on_bar, etc.)
- Data subscriptions
- Order management
- Portfolio access
- Indicator integration
- Common strategy patterns

### 🔬 [backtesting.md](backtesting.md)
**Read when:** User wants to backtest strategies
- High-level API (BacktestNode)
- Low-level API (BacktestEngine)
- Configuration objects
- Fill models and slippage
- Multiple backtest runs
- Performance optimization

### 🚀 [live-trading.md](live-trading.md)
**Read when:** User wants to deploy strategies live or needs production setup
- TradingNode configuration
- Database setup (Redis)
- Multi-venue deployment
- Execution reconciliation
- Risk management in production
- Monitoring and safety

### 📊 [data-models.md](data-models.md)
**Read when:** User needs details about data types, models, or the type system
- Core data types (QuoteTick, TradeTick, Bar)
- Identifiers (InstrumentId, Venue, Symbol)
- Order types
- Instrument types
- Events and messages
- Parquet data catalog

### 🔌 [integrations.md](integrations.md)
**Read when:** User asks about connecting to exchanges or data providers
- Supported venues (Binance, Bybit, Interactive Brokers, etc.)
- Integration status levels
- Adapter configuration

### 🎭 [actors.md](actors.md)
**Read when:** User needs to understand the Actor base class or build non-trading components
- Actor vs Strategy relationship
- Lifecycle methods
- Data subscriptions and handlers
- Cache and portfolio access
- Custom data publishing
- Signal generation patterns

### 📉 [indicators.md](indicators.md)
**Read when:** User wants to use or create technical indicators
- Built-in indicators (EMA, RSI, MACD, Bollinger Bands, ATR, etc.)
- Indicator registration with strategies/actors
- Manual vs automatic updates
- Custom indicator implementation
- Warm-up and initialization

### 🗄️ [cache.md](cache.md)
**Read when:** User needs to query market data, orders, positions, or instruments
- Cache configuration
- Instrument queries
- Market data access (quotes, trades, bars, order book)
- Order and position queries
- Account information
- Common cache patterns

### 📋 [orders.md](orders.md)
**Read when:** User needs to create, submit, or manage orders
- Order types (Market, Limit, Stop, Trailing, etc.)
- OrderFactory usage
- Order submission and modification
- Order events and lifecycle
- Bracket orders and contingencies (OTO, OCO)
- Order emulation

### 💰 [portfolio.md](portfolio.md)
**Read when:** User needs account, balance, position, or PnL information
- Portfolio vs Cache distinction
- Account balances and margins
- Position tracking
- PnL calculations
- Account types (Cash, Margin)
- Portfolio analyzer

### ⚡ [execution.md](execution.md)
**Read when:** User needs to understand execution flow or implement execution algorithms
- Execution flow (Strategy → RiskEngine → ExecutionEngine → Venue)
- OMS types (NETTING vs HEDGING)
- Risk engine configuration
- Built-in execution algorithms (TWAP)
- Custom execution algorithm implementation
- Order emulation

### 🔧 [adapters.md](adapters.md)
**Read when:** User wants to implement a custom adapter or understand adapter architecture
- Adapter components (DataClient, ExecutionClient, InstrumentProvider)
- Custom adapter implementation
- Client factories
- Configuration classes
- Registering custom adapters

### 💡 [examples.md](examples.md)
**Read when:** User wants working code examples or implementation patterns
- Complete strategy examples
- Risk management patterns
- Multi-instrument strategies
- Custom indicators
- MessageBus patterns
- Advanced use cases

### ✅ [best-practices.md](best-practices.md)
**Read when:** User needs guidance on proper implementation or optimization
- Configuration management
- Testing strategies
- Performance optimization
- Error handling
- Live trading safety
- Code organization

### 🔧 [troubleshooting.md](troubleshooting.md)
**Read when:** User encounters errors or issues
- Common installation problems
- Data loading issues
- Backtesting errors
- Live trading connectivity
- Performance problems

## Quick Decision Guide

**"How do I install NautilusTrader?"**
→ Read `installation.md`

**"I want to create a trading strategy"**
→ Read `strategy-development.md`, then `examples.md`

**"How do I backtest my strategy?"**
→ Read `backtesting.md`

**"I need to understand the system architecture"**
→ Read `architecture.md`

**"How do I deploy my strategy live?"**
→ Read `live-trading.md`, then `best-practices.md`

**"What data types are available?"**
→ Read `data-models.md`

**"Can I connect to Binance/Bybit/IB?"**
→ Read `integrations.md`

**"How do I implement a custom adapter?"**
→ Read `adapters.md`

**"How do I use technical indicators?"**
→ Read `indicators.md`

**"What is an Actor vs a Strategy?"**
→ Read `actors.md`, then `strategy-development.md`

**"How do I query orders and positions?"**
→ Read `cache.md`

**"How do I submit and manage orders?"**
→ Read `orders.md`

**"How do I check my account balance/PnL?"**
→ Read `portfolio.md`

**"How does order execution work?"**
→ Read `execution.md`

**"Show me code examples"**
→ Read `examples.md`

**"My code isn't working"**
→ Read `troubleshooting.md`

**"What are the best practices?"**
→ Read `best-practices.md`

## Reading Multiple Files

For comprehensive tasks, read multiple files in order:

**Building a complete trading system:**
1. `installation.md` - Set up environment
2. `architecture.md` - Understand components
3. `actors.md` - Understand base component
4. `strategy-development.md` - Write strategy
5. `indicators.md` - Add technical indicators
6. `orders.md` - Understand order management
7. `backtesting.md` - Test strategy
8. `best-practices.md` - Optimize implementation
9. `live-trading.md` - Deploy to production

**Understanding data and state:**
1. `data-models.md` - Data types and structures
2. `cache.md` - Querying cached data
3. `portfolio.md` - Account and position info

**Custom integrations:**
1. `integrations.md` - Existing adapters
2. `adapters.md` - Implementing custom adapters
3. `execution.md` - Execution flow understanding

**Advanced execution:**
1. `orders.md` - Order types and management
2. `execution.md` - Execution algorithms and flow
3. `best-practices.md` - Risk management

**Debugging an existing system:**
1. `troubleshooting.md` - Identify common issues
2. Relevant component file - Deep dive into specific area
3. `best-practices.md` - Verify implementation quality

## Version Information

- **Current Status:** Active development (beta releases)
- **Release Schedule:** Approximately bi-weekly
- **API Stability:** Improving but breaking changes possible until v2.x
- **Latest Version:** Check https://github.com/nautechsystems/nautilus_trader/releases

## Important Notes for AI Assistants

When helping users with Nautilus Trader:

1. **Read selectively** - Only read the files relevant to the user's question
2. **Start with the main file** - This SKILL.md provides context
3. **Reference documentation** - Always check official docs for latest API
4. **Consider user context** - Backtest vs. live, beginner vs. advanced
5. **Emphasize testing** - Always recommend backtesting before live deployment
6. **Be aware of breaking changes** - API is still evolving
7. **Prioritize safety** - Risk management is critical in live trading

This skill should be used whenever users ask about algorithmic trading, event-driven backtesting, strategy development, or production trading systems in Python.
