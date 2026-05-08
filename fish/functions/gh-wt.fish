function gh-wt
    set -l pr_number $argv[1]
    if test -z "$pr_number"
        echo "Usage: gh-wt <PR_NUMBER>"
        return 1
    end

    set -l branch_name (gh pr view "$pr_number" --json headRefName --template '{{.headRefName}}')
    if test -z "$branch_name"
        return 1
    end

    set -l safe_branch (string replace -a / - -- $branch_name)
    set -l tmp_dir "/tmp/gh-wt-$pr_number-$safe_branch"

    git fetch origin "pull/$pr_number/head"

    if git worktree list | grep -qF "[$branch_name]"
        echo "⚠️  Branch '$branch_name' is already checked out somewhere else."
        echo "💡 Creating worktree with detached HEAD..."
        git worktree add "$tmp_dir" FETCH_HEAD
    else if git show-ref --verify --quiet "refs/heads/$branch_name"
        git worktree add "$tmp_dir" "$branch_name"
    else
        git worktree add -b "$branch_name" "$tmp_dir" FETCH_HEAD
    end

    if test -d "$tmp_dir"
        echo "🚀 Entering worktree at $tmp_dir"
        cd "$tmp_dir"
    else
        echo "❌ Failed to create worktree."
        return 1
    end
end
