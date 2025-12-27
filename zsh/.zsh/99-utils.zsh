# worktree-manager.sh - Bash version of git worktree manager with Claude support

w() {
    local projects_dir="$HOME/repos"
    local worktrees_dir="$HOME/repos/worktrees"

    # Handle special flags
    if [[ "$1" == "--list" ]]; then
        echo "=== All Worktrees ==="
        # Check new location
        if [[ -d "$worktrees_dir" ]]; then
            for project in "$worktrees_dir"/*/; do
                [[ -d "$project" ]] || continue
                project_name=$(basename "$project")
                echo "\n[$project_name]"
                for wt in "$project"/*/; do
                    [[ -d "$wt" ]] || continue
                    echo "  • $(basename "$wt")"
                done
            done
        fi
        # Also check old core-wts location
        if [[ -d "$projects_dir/core-wts" ]]; then
            echo "\n[core] (legacy location)"
            for wt in "$projects_dir/core-wts"/*/; do
                [[ -d "$wt" ]] || continue
                echo "  • $(basename "$wt")"
            done
        fi
        return 0

    elif [[ "$1" == "--rm" ]]; then
        shift
        local project="$1"
        local worktree="$2"
        if [[ -z "$project" || -z "$worktree" ]]; then
            echo "Usage: w --rm <project> <worktree>"
            return 1
        fi
        # Check both locations for core
        if [[ "$project" == "core" && -d "$projects_dir/core-wts/$worktree" ]]; then
            (cd "$projects_dir/$project" && git worktree remove "$projects_dir/core-wts/$worktree")
        else
            local wt_path="$worktrees_dir/$project/$worktree"
            if [[ ! -d "$wt_path" ]]; then
                echo "Worktree not found: $wt_path"
                return 1
            fi
            (cd "$projects_dir/$project" && git worktree remove "$wt_path")
        fi
        return $?
    fi

    # Normal usage: w <project> <worktree> [command...]
    local project="$1"
    local worktree="$2"
    shift 2
    local command=("$@")

    if [[ -z "$project" || -z "$worktree" ]]; then
        echo "Usage: w <project> <worktree> [command...]"
        echo "w --list"
        echo "w --rm <project> <worktree>"
        return 1
    fi

    # Check if project exists
    if [[ ! -d "$projects_dir/$project" ]]; then
        echo "Project not found: $projects_dir/$project"
        return 1
    fi

    # Determine worktree path - check multiple locations
    local wt_path=""
    if [[ "$project" == "core" ]]; then
        if [[ -d "$projects_dir/core-wts/$worktree" ]]; then
            wt_path="$projects_dir/core-wts/$worktree"
        elif [[ -d "$worktrees_dir/$project/$worktree" ]]; then
            wt_path="$worktrees_dir/$project/$worktree"
        fi
    else
        if [[ -d "$worktrees_dir/$project/$worktree" ]]; then
            wt_path="$worktrees_dir/$project/$worktree"
        fi
    fi

    # If worktree doesn't exist, create it
    if [[ -z "$wt_path" || ! -d "$wt_path" ]]; then
        echo "Creating new worktree: $worktree"
        mkdir -p "$worktrees_dir/$project"
        local branch_name="$USER/$worktree"
        wt_path="$worktrees_dir/$project/$worktree"
        (cd "$projects_dir/$project" && git worktree add "$wt_path" -b "$branch_name") || {
            echo "Failed to create worktree"
            return 1
        }
    fi

    # Execute based on number of arguments
    if [[ ${#command[@]} -eq 0 ]]; then
        cd "$wt_path"
    else
        local old_pwd="$PWD"
        cd "$wt_path"
        "${command[@]}"
        local exit_code=$?
        cd "$old_pwd"
        return $exit_code
    fi
}

