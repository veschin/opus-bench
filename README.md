# opus-bench

Daily canary for Claude Opus models. Compares Opus 4.6, Opus 4.7, and
Z.AI GLM-5.1 via the `claude` CLI with Sonnet polyrubric scoring.

## Table of contents

- [Install](#install)
- [Usage](#usage)
- [Scoring](#scoring)
- [Output](#output)
- [Limitations](#limitations)
- [Design history](#design-history)

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/veschin/opus-bench/main/install.sh | bash
```

| Dependency | What for | Install |
|------------|----------|---------|
| [claude](https://docs.claude.com/en/docs/claude-code) | Target calls + Sonnet judge | `npm i -g @anthropic-ai/claude-code` |
| [gum](https://github.com/charmbracelet/gum) | TUI spinners and panels | `brew install gum` / `pacman -S gum` |
| python3 | Inline scoring (stdlib only) | ships with most distros |

Optional: Z.AI API key at `~/.config/GoLeM/zai_api_key` for GLM-5.1.
If missing, GLM is skipped.

## Usage

```sh
./opus-bench               # full run (K=3), verdict only
./opus-bench --verbose     # full run, all tables + verdict
./opus-bench --fast        # K=1 smoke check
./opus-bench --fast -v     # smoke + tables
```

Full run: ~109 API calls, ~$14-20, 8-12 min.

## Scoring

Six tasks (`reason`, `trace`, `code`, `bugs`, `behave`, `refusal`),
K=3 repeats each. Three layers:

1. **Shadow correctness** -- programmatic exact match / unit tests
2. **Sonnet polyrubric** -- 10 axes per response (correctness, depth +
   8 defect axes), evidence quote required on defect >= 4
3. **Thinking effort** -- `max(0, output_tokens - len(text)/3.5)`,
   duration, thinking block count

Final Sonnet analyst emits a `USE: <model>` verdict from aggregated metrics.

## Output

- `results/bench_<DATE>.json` -- aggregated metrics + verdict
- `results/<task>_<model>_<DATE>_r<N>.json` -- raw per-call responses

## Limitations

- Measures CLI inference, not the raw model. System prompt, plugins, MCP
  are included; a CLI regression is attributed to the model.
- Same Sonnet judge for all targets: relative comparisons are valid,
  absolute defect levels are not.
- K=3 is not statistically significant below ~10pp. Treat the JSON
  history as a control chart.

## Design history

<details>
<summary><b>v1 -> v2 -> v3 evolution</b></summary>

### v1 -- direct thinking measurement

Measured `len(block.thinking)` and scored tasks via English-only regex.

Two problems surfaced immediately:

| Issue | Impact |
|-------|--------|
| Opus 4.7 returns thinking encrypted (populated `signature`, empty `thinking` text) | Bench read 0 tokens and pinned 4.7 at DEGRADED while answers were correct on every task |
| English-only regex scoring | Russian-language responses missed all matches, losing points purely for language choice |

### v2 -- pass/fail binary scoring

Dropped the thinking metric entirely. Scored each task pass/fail.

Both models hit 6/6 on a six-task suite, making a known quality
difference between them invisible. Binary scoring lacked the
resolution to detect anything short of a catastrophic regression.

### v3 -- current

| Change | Fixes |
|--------|-------|
| Sonnet polyrubric judge (content-based, language-agnostic) | English-only regex bias |
| `output_tokens - visible_text` as thinking proxy | Encrypted thinking blocks |
| Continuous 0-10 axes instead of pass/fail | Invisible degradation between passing models |

</details>
