# RTK: Rust Token Killer

RTK is a token-optimized CLI proxy that filters bash output before it reaches the model, cutting token usage by up to 90 percent on commands with noisy output.

## Meta Commands

Always invoke these directly as `rtk ...`; they are not commands RTK proxies, they are RTK's own interface.

```bash
rtk gain              # Show cumulative token savings
rtk gain --history    # Show per-command usage history with savings
rtk discover          # Scan Claude Code history for commands that could have used RTK but didn't
rtk proxy <cmd>       # Run <cmd> raw, with no output filtering (use this to debug a suspected filtering problem)
```

## Installation Verification

Run all three; each should succeed as shown, not fail:

```bash
rtk --version         # Prints "rtk X.Y.Z"
rtk gain              # Runs without a "command not found" error
which rtk             # Confirms the resolved binary is the intended one
```

**Name collision:** if `rtk gain` fails or behaves unexpectedly, the `rtk` on `PATH` may resolve to `reachingforthejack/rtk` ("Rust Type Kit," an unrelated tool) instead of this one. Confirm with `which rtk` and fix `PATH` ordering if so.

## Hook-Based Usage

Every other shell command is rewritten transparently by a Claude Code hook to route through RTK, at no extra token cost. For example, a plain `git status` is automatically executed as `rtk git status`; no manual `rtk` prefix is needed for ordinary commands.
