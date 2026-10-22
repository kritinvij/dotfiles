# RTK: Rust Token Killer

RTK is a CLI proxy that filters bash output before it reaches the model. It cuts token use by up to 90 percent on noisy commands.

## Hook-based usage

A Claude Code hook routes every shell command through RTK. A plain `git status` runs as `rtk git status`, so write the plain command. Adding the prefix yourself can produce `rtk rtk git status`, which fails.

The filter can hide output you need. If a `diff`, `grep`, or `ls` result looks empty or cut short, rerun it with `rtk proxy <cmd>` for raw output.

## Meta commands

Type these with the `rtk` prefix. They are RTK's own interface, so the hook doesn't proxy them.

```bash
rtk gain              # Show cumulative token savings
rtk gain --history    # Show per-command usage history with savings
rtk discover          # Scan Claude Code history for commands that could have used RTK
rtk proxy <cmd>       # Run <cmd> raw, with no output filtering
```

## Installation check

Each of these should succeed:

```bash
rtk --version         # Prints "rtk X.Y.Z"
rtk gain              # Runs without "command not found"
which rtk             # Shows the resolved binary
```

**Name collision.** If `rtk gain` fails or behaves oddly, `PATH` may resolve to `reachingforthejack/rtk`, an unrelated "Rust Type Kit". Check with `which rtk` and fix the `PATH` order.
