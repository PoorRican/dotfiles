#!/usr/bin/env python3
"""
Brainstorm orchestration helper.
Launches parallel Claude sub-tasks for feature brainstorming.

Usage:
    python orchestrate.py explore --feature "OAuth authentication" --path /repo
    python orchestrate.py validate --feature "OAuth authentication" --path /repo --context exploration-summary.md
    python orchestrate.py assess --feature "OAuth authentication" --context validation-summary.md
"""

import argparse
import subprocess
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

SESSIONS_DIR = Path("/home/claude/brainstorm-sessions")
MODEL = "claude-sonnet-4-20250514"

EXPLORE_ANGLES = {
    "architecture": "Architecture - overall structure, module boundaries, data flow patterns",
    "similar": "Similar features - existing features with comparable patterns to reference",
    "data": "Data layer - models, schemas, database interactions, state management",
    "api": "API surface - endpoints, interfaces, contracts that would be affected",
    "testing": "Testing patterns - how similar features are tested, test infrastructure",
}

VALIDATE_ANGLES = {
    "patterns": "Pattern alignment - does the approach fit existing codebase patterns?",
    "research": "Technical research - best practices, library options, security considerations",
    "edges": "Edge cases - error handling, failure modes, boundary conditions",
    "performance": "Performance - scalability concerns, potential bottlenecks",
}

ASSESS_ANGLES = {
    "mvp": "MVP approach - minimum viable implementation, fastest path",
    "robust": "Robust approach - production-ready, handles edge cases",
    "alternative": "Alternative approach - different architecture or pattern",
}


def run_subtask(prompt: str, output_file: Path) -> dict:
    """Run a Claude sub-task and return result."""
    cmd = [
        "claude",
        "--model", MODEL,
        "--print",
        prompt
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )

        output_file.write_text(result.stdout)

        return {
            "file": str(output_file),
            "success": result.returncode == 0,
            "error": result.stderr if result.returncode != 0 else None
        }
    except subprocess.TimeoutExpired:
        return {
            "file": str(output_file),
            "success": False,
            "error": "Timeout after 5 minutes"
        }
    except Exception as e:
        return {
            "file": str(output_file),
            "success": False,
            "error": str(e)
        }


def build_explore_prompt(feature: str, angle_name: str, angle_desc: str, codebase_path: str) -> str:
    return f"""You are exploring a codebase to understand how to implement: {feature}

Your specific focus: {angle_desc}

Codebase location: {codebase_path}

Instructions:
1. Explore relevant files using view and bash tools
2. Document key findings below
3. Note: existing patterns, relevant abstractions, potential integration points, dependencies

Keep findings concise and actionable. Structure your response as a markdown document with clear sections."""


def build_validate_prompt(feature: str, angle_name: str, angle_desc: str, codebase_path: str, context: str) -> str:
    return f"""You are validating an implementation approach for: {feature}

Exploration context:
{context}

Your validation focus: {angle_desc}

Codebase location: {codebase_path}

Instructions:
1. Research best practices using web search if needed
2. Validate against codebase patterns
3. Flag any concerns, risks, or open questions

Be critical - identify potential problems early. Structure your response as a markdown document."""


def build_assess_prompt(feature: str, angle_name: str, angle_desc: str, context: str) -> str:
    return f"""You are creating an implementation proposal for: {feature}

Context from exploration and validation:
{context}

Your assessment focus: {angle_desc}

Instructions:
1. Create a concrete implementation proposal
2. Estimate effort and complexity (use T-shirt sizes: XS, S, M, L, XL)
3. Identify prerequisites and blockers

Structure your response with these sections:
## Approach Summary
## Implementation Steps
## Effort Estimate
## Risks and Mitigations
## Prerequisites"""


def explore(feature: str, codebase_path: str, angles: list[str] | None = None):
    """Run exploration phase with parallel sub-tasks."""
    SESSIONS_DIR.mkdir(parents=True, exist_ok=True)

    if angles is None:
        angles = list(EXPLORE_ANGLES.keys())

    tasks = []
    for angle in angles:
        if angle not in EXPLORE_ANGLES:
            print(f"Warning: Unknown angle '{angle}', skipping")
            continue

        prompt = build_explore_prompt(feature, angle, EXPLORE_ANGLES[angle], codebase_path)
        output_file = SESSIONS_DIR / f"explore-{angle}.md"
        tasks.append((prompt, output_file, angle))

    print(f"Launching {len(tasks)} exploration sub-tasks...")

    results = []
    with ThreadPoolExecutor(max_workers=5) as executor:
        futures = {executor.submit(run_subtask, p, o): a for p, o, a in tasks}
        for future in as_completed(futures):
            angle = futures[future]
            result = future.result()
            results.append(result)
            status = "✓" if result["success"] else "✗"
            print(f"  {status} {angle}: {result['file']}")

    # Combine results
    summary_file = SESSIONS_DIR / "exploration-summary.md"
    with open(summary_file, "w") as f:
        f.write(f"# Exploration Summary: {feature}\n\n")
        for angle in angles:
            explore_file = SESSIONS_DIR / f"explore-{angle}.md"
            if explore_file.exists():
                f.write(f"## {angle.title()}\n\n")
                f.write(explore_file.read_text())
                f.write("\n\n---\n\n")

    print(f"\nSummary written to: {summary_file}")
    return results


def validate(feature: str, codebase_path: str, context_file: str, angles: list[str] | None = None):
    """Run validation phase with parallel sub-tasks."""
    context = Path(context_file).read_text() if context_file else ""

    if angles is None:
        angles = list(VALIDATE_ANGLES.keys())

    tasks = []
    for angle in angles:
        if angle not in VALIDATE_ANGLES:
            print(f"Warning: Unknown angle '{angle}', skipping")
            continue

        prompt = build_validate_prompt(feature, angle, VALIDATE_ANGLES[angle], codebase_path, context)
        output_file = SESSIONS_DIR / f"validate-{angle}.md"
        tasks.append((prompt, output_file, angle))

    print(f"Launching {len(tasks)} validation sub-tasks...")

    results = []
    with ThreadPoolExecutor(max_workers=4) as executor:
        futures = {executor.submit(run_subtask, p, o): a for p, o, a in tasks}
        for future in as_completed(futures):
            angle = futures[future]
            result = future.result()
            results.append(result)
            status = "✓" if result["success"] else "✗"
            print(f"  {status} {angle}: {result['file']}")

    # Combine results
    summary_file = SESSIONS_DIR / "validation-summary.md"
    with open(summary_file, "w") as f:
        f.write(f"# Validation Summary: {feature}\n\n")
        for angle in angles:
            validate_file = SESSIONS_DIR / f"validate-{angle}.md"
            if validate_file.exists():
                f.write(f"## {angle.title()}\n\n")
                f.write(validate_file.read_text())
                f.write("\n\n---\n\n")

    print(f"\nSummary written to: {summary_file}")
    return results


def assess(feature: str, context_file: str, angles: list[str] | None = None):
    """Run assessment phase with parallel sub-tasks."""
    context = Path(context_file).read_text() if context_file else ""

    if angles is None:
        angles = list(ASSESS_ANGLES.keys())

    tasks = []
    for angle in angles:
        if angle not in ASSESS_ANGLES:
            print(f"Warning: Unknown angle '{angle}', skipping")
            continue

        prompt = build_assess_prompt(feature, angle, ASSESS_ANGLES[angle], context)
        output_file = SESSIONS_DIR / f"assess-{angle}.md"
        tasks.append((prompt, output_file, angle))

    print(f"Launching {len(tasks)} assessment sub-tasks...")

    results = []
    with ThreadPoolExecutor(max_workers=3) as executor:
        futures = {executor.submit(run_subtask, p, o): a for p, o, a in tasks}
        for future in as_completed(futures):
            angle = futures[future]
            result = future.result()
            results.append(result)
            status = "✓" if result["success"] else "✗"
            print(f"  {status} {angle}: {result['file']}")

    # Combine results
    summary_file = SESSIONS_DIR / "assessment-summary.md"
    with open(summary_file, "w") as f:
        f.write(f"# Assessment Summary: {feature}\n\n")
        for angle in angles:
            assess_file = SESSIONS_DIR / f"assess-{angle}.md"
            if assess_file.exists():
                f.write(f"## {angle.title()} Approach\n\n")
                f.write(assess_file.read_text())
                f.write("\n\n---\n\n")

    print(f"\nSummary written to: {summary_file}")
    return results


def main():
    parser = argparse.ArgumentParser(description="Brainstorm orchestration helper")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Explore command
    explore_parser = subparsers.add_parser("explore", help="Run exploration phase")
    explore_parser.add_argument("--feature", required=True, help="Feature description")
    explore_parser.add_argument("--path", required=True, help="Codebase path")
    explore_parser.add_argument("--angles", nargs="+", help="Specific angles to explore")

    # Validate command
    validate_parser = subparsers.add_parser("validate", help="Run validation phase")
    validate_parser.add_argument("--feature", required=True, help="Feature description")
    validate_parser.add_argument("--path", required=True, help="Codebase path")
    validate_parser.add_argument("--context", help="Path to exploration summary")
    validate_parser.add_argument("--angles", nargs="+", help="Specific angles to validate")

    # Assess command
    assess_parser = subparsers.add_parser("assess", help="Run assessment phase")
    assess_parser.add_argument("--feature", required=True, help="Feature description")
    assess_parser.add_argument("--context", help="Path to validation summary")
    assess_parser.add_argument("--angles", nargs="+", help="Specific angles to assess")

    args = parser.parse_args()

    if args.command == "explore":
        explore(args.feature, args.path, args.angles)
    elif args.command == "validate":
        validate(args.feature, args.path, args.context, args.angles)
    elif args.command == "assess":
        assess(args.feature, args.context, args.angles)


if __name__ == "__main__":
    main()
