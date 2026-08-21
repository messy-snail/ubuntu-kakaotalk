<div align="center">

# ubuntu-kakaotalk

**Run the Windows build of KakaoTalk on Ubuntu 24.04 through WineHQ staging**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Release](https://img.shields.io/github/v/release/messy-snail/ubuntu-kakaotalk?color=blue)](https://github.com/messy-snail/ubuntu-kakaotalk/releases/latest)
[![lint](https://github.com/messy-snail/ubuntu-kakaotalk/actions/workflows/lint.yml/badge.svg)](https://github.com/messy-snail/ubuntu-kakaotalk/actions/workflows/lint.yml)

[![Ubuntu 24.04 LTS](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://releases.ubuntu.com/24.04/)
[![WineHQ staging](https://img.shields.io/badge/WineHQ-staging%2011.15%2B-9C27B0)](https://wiki.winehq.org/Ubuntu)
[![KakaoTalk](https://img.shields.io/badge/KakaoTalk-26.7.1.5263-FEE500?logo=kakaotalk&logoColor=3C1E1E)](https://www.kakaocorp.com/)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)](./docker/README.md)

[한국어](./README.md) | English

</div>

---

KakaoTalk is proprietary software owned by Kakao Corp. This repository **only automates the
install and launch procedure** — it does not redistribute any KakaoTalk binary and is not
affiliated with Kakao.

## Three ways to install

| | Method | Pick this if | Command |
|---|---|---|---|
| 🤖 | **Let an agent do it** | You want the terminal work done for you | Copy the prompt below |
| 🔧 | **Install directly** | You want it on the host, now | `./install.sh` |
| 📦 | **Docker** | You want your host left alone | `./docker/kakaotalk.sh build` |

Whichever you pick, the KakaoTalk installer is fetched from the official CDN automatically and
runs in silent mode. **There is no `Next` button to click.**

### 🤖 1. Let an agent do it

![effort: lowest](https://img.shields.io/badge/effort-lowest-brightgreen) ![sudo: agent runs it](https://img.shields.io/badge/sudo-agent_runs_it-blue)

Hand it to a coding agent such as Codex or Claude Code. From the repository root, ask:

```text
Read README.md and KAKAOTALK_WINE_INSTALL.md, then install with ./install.sh.
Show me any sudo commands first, and do not delete an existing Wine prefix.
When you are done, report the self-check results and whether I still need to set
Display → Font → 나눔고딕.
```

This just runs `install.sh` on your behalf, so the result is identical to option 2. The
difference is that the agent also handles the `sudo` prerequisites.

### 🔧 2. Install directly

![effort: moderate](https://img.shields.io/badge/effort-moderate-yellow) ![sudo: you run it](https://img.shields.io/badge/sudo-you_run_it-orange)

```bash
git clone https://github.com/messy-snail/ubuntu-kakaotalk.git
cd ubuntu-kakaotalk
./install.sh
```

The only things you need up front are apt packages — WineHQ staging, winetricks, and the
`fonts-nanum` family. Those need `sudo`, so the script never runs them for you: **if something
is missing it prints the exact commands and stops.** Run them, then run `./install.sh` again.

Wine Gecko, Mono, `cjkfonts`, and the KakaoTalk installer are all fetched automatically. The
full procedure is in [`KAKAOTALK_WINE_INSTALL.md`](./KAKAOTALK_WINE_INSTALL.md).

### 📦 3. Docker

![effort: moderate](https://img.shields.io/badge/effort-moderate-yellow) ![isolation: host untouched](https://img.shields.io/badge/isolation-host_untouched-brightgreen)

```bash
./docker/kakaotalk.sh build
./docker/kakaotalk.sh run
```

Everything including the apt packages is prepared inside the image, so there is no `sudo` step —
you only need access to the Docker daemon. Your login session and chat data live outside the
image in `~/.local/share/kakaotalk-docker`, so they survive a rebuild.

See [`docker/README.md`](./docker/README.md) for details.

## Running it

```bash
~/.local/bin/kakaotalk-wine
```

Searching for `KakaoTalk` in your desktop app menu launches the same wrapper. For Docker, use
`./docker/kakaotalk.sh run`.

## Required in-app setting

> [!IMPORTANT]
> After logging in, you must pick this inside KakaoTalk:
>
> ```text
> Settings → Display → Font → 나눔고딕
> ```
>
> It is the `Display` tab, not `Settings → Chat`. Until you set it, Korean text in the compose
> box can render as garbage or freeze Wine on the first keystroke, even when the chat body looks
> fine. This applies to every install method.

## Known issues

| Symptom | Cause |
|---|---|
| Blank chat room with a repeated `Encountered an improper argument.` dialog | winetricks `gdiplus`, `riched20`, `vcrun2019`. This repository never installs them |
| Only the compose box shows broken Korean | The **required in-app setting** above was not applied |
| Docker install, but the font mapping is broken | The v1.0.0 image was built under a non-UTF-8 locale. Fixed in v1.0.1 |
| First launch dies instantly with `c0000409` | The launcher retries automatically, up to three times |

> [!WARNING]
> Do not install `winetricks gdiplus`, `riched20`, or `vcrun2019`. They are the direct cause of
> the blank chat window. This repository uses only the font-only `cjkfonts` verb.

Diagnostic commands, recovery steps, and the hypotheses that were investigated and **ruled out**
(Wine build, GPU, DLL overrides, WIC, WebView2, and more) are in
[`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md).

## Documentation

| Document | When to read it |
|---|---|
| [`KAKAOTALK_WINE_INSTALL.md`](./KAKAOTALK_WINE_INSTALL.md) | Walking the install by hand, or changing environment variables |
| [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) | Something broke |
| [`docker/README.md`](./docker/README.md) | Running it under Docker |
| [`test/README.md`](./test/README.md) | Regression-testing a change |
| [`CHANGELOG.md`](./CHANGELOG.md) | What changed between releases |

The verified baseline is Ubuntu 24.04.4 LTS + WineHQ staging 11.15 + KakaoTalk 26.7.1.5263
(re-verified 2026-08-21). These are not hard pins — later versions are allowed.

## Contributing

Issues and PRs are welcome. Including this in a bug report narrows things down much faster:

```bash
/opt/wine-staging/bin/wine --version
cat "${KAKAOTALK_PREFIX:-$HOME/.wine-kakaotalk-clean}/winetricks.log"
grep -m1 '"ProductName"=' "${KAKAOTALK_PREFIX:-$HOME/.wine-kakaotalk-clean}/system.reg"
```

Commits follow [Conventional Commits](https://www.conventionalcommits.org/) and versioning is
handled by [commitizen](https://commitizen-tools.github.io/commitizen/).

```bash
uv run --no-project cz commit                     # write a commit
shellcheck -x install.sh docker/*.sh test/*.sh    # the same lint CI runs
```

## License and notices

The scripts and documentation in this repository are [MIT licensed](./LICENSE).

KakaoTalk is proprietary software owned by Kakao Corp., and the associated trademarks belong to
Kakao. This repository neither bundles nor redistributes KakaoTalk; it only automates downloading
it from the official CDN and installing it. It is not sponsored or endorsed by Kakao. Your use of
KakaoTalk is governed by Kakao's terms of service. Wine is a work of the
[WineHQ project](https://www.winehq.org/) under its own license.
