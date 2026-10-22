# Using Git Boy

Open **Help → Git Boy Guide**, press **Command–?**, or click **HELP** at the lower right for the nine-step spotlight walkthrough. It dims the app and highlights each real control; Next and Back move through the tour, and Close or Escape exits.

## Review code

1. Choose **REPOSITORY → Open Repository** and select a Git folder, or open a code-review link from Codex.
2. File badges use green for Added, pink for Deleted, blue for Modified/Renamed, and amber for Conflict. Symbols and labels accompany the colors. Click a changed file on the left. Green `+` lines are additions; red `−` lines are removals.
3. Read the heading above the file list. **Working changes** means edits not committed yet. **Comparing committed changes** means a branch/commit comparison.
4. For working changes, **Working file** shows unstaged edits; **Staged for commit** shows what is ready for the next commit. Git Boy automatically chooses the side that has changes. An empty side explains how to find the other one.
5. Press **A / Review** to save your reading progress for that content. It does not commit, approve a release, push, or deploy.

The D-pad is optional: up/down changes files; left/right opens history/review. Clicking the file list and tabs does the same work.

## Ask AI what something means

1. Optionally highlight some code in the diff.
2. Press **B / Ask AI**. The popup stays beside the button.
3. Choose an explanation, review, or conflict question; add your own question if useful.
4. Read the exact prompt in the preview. It includes the selected lines, or the displayed diff/conflict context when nothing is highlighted. Very large excerpts are limited and labeled.
5. Click **Copy prompt for Codex / ChatGPT**, then paste it into your conversation and send it there.

There is no AI model running inside Git Boy. Opening the popup does not copy or transmit code. The explicit Copy button places the displayed prompt on your clipboard; you decide where to paste and send it.

## Resolve a conflict

For a fresh example, open the last page of the guide and choose **Open safe conflict practice…**. It creates a separate local learning folder and does not modify your working repositories.

1. Inspect **Original**, **Current side**, and **Incoming side**.
2. Choose **Use this version as the draft resolution** if one side is a useful starting point, or open **Edit resolution** directly.
3. Edit the text to keep the correct content and remove the `<<<<<<<`, `=======`, and `>>>>>>>` marker lines. Ask AI can explain both sides first.
4. **Save resolution** writes the working file and keeps an original backup. Outside edits are checked before writing. Unsaved drafts stay in memory across refresh and file navigation; save before quitting the app.
5. **Stage resolved file** marks the conflict resolved. The staged diff becomes visible for inspection.
6. Use **Git Actions** to commit when you are ready. Committing, pushing, and deploying are separate decisions.

An earlier practice file may already be resolved and staged. The app says so and displays the staged changes; it will not pretend there is still a conflict. If a resolution keeps the current content unchanged, there may be no file diff even though the merge is ready for a merge commit.

## Other controls

- **Git Actions:** stage/unstage, commit, fetch, pull, and push. Push asks for confirmation. Staging and commit controls appear in Working changes.
- **Refresh:** reload the current repository; it does not fetch or publish.
- **History:** recent commits. **Branches:** local branches; switching requires a clean working state.
- **Review Link · This Mac:** copies a local link and explains its scope. It reopens the repository, comparison, and file on this Mac. It does not upload code and is not a public share link. Another device cannot access your local checkout through it.

The top line is a system label, not a power switch. The battery light indicates the app is running; its glow changes during Git operations.
