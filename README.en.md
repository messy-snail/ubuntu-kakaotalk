<div align="center">

# ubuntu-kakaotalk

**Automated installer and Docker environment for running Windows KakaoTalk on Ubuntu 24.04 via WineHQ staging**

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

> [!WARNING]
> Do not install `winetricks gdiplus`, `riched20`, or `vcrun2019`. These DLL verbs cause blank
> chat windows and repeated `Encountered an improper argument.` dialogs. This repository uses
> only the font-only `cjkfonts` verb.

## What it does

- **Clean prefix** — a win64 prefix in Windows 10 mode with `cjkfonts` as the only winetricks
  verb. The DLL verbs that break chat rendering are excluded from the start.
- **Nanum font wiring** — copies NanumGothic, NanumBarunGothic, and NanumMyeongjo out of the
  host's `fonts-nanum` package into the prefix, then wires up two distinct layers. When Wine
  substitutes a Windows font request (`MS Shell Dlg`, `Segoe UI`, `맑은 고딕`) it draws with
  NanumBarunGothic; when KakaoTalk asks for `나눔고딕`, the family you pick inside the app, it
  resolves to NanumGothic. `FontSubstitutes` and `FontLink\SystemLink` handle the former,
  `Fonts\Replacements` the latter.
- **Fetches everything it can** — downloads the KakaoTalk installer straight from the official
  CDN and caches it under `~/.cache/kakaotalk-installer`. Wine Gecko, Mono, and `cjkfonts` are
  fetched automatically too.
- **Integrity checks** — Wine Gecko and Mono are matched against pinned SHA-256 digests. The
  KakaoTalk installer is validated for size and a PE (`MZ`) header before it runs; its hash is
  printed rather than pinned, because the CDN keeps serving newer builds.
- **Non-destructive** — never deletes or resets a prefix. If a prefix already contains the
  forbidden DLLs, the script stops instead of trying to repair it and points you at a new path.
- **Desktop integration** — a retrying launcher, a 256px icon extracted from the `.exe`, and
  desktop entries for the app and the `kakaoopen://` protocol handler.
- **Self-check** — after install it verifies the Wine version, prefix mode, absence of forbidden
  verbs, fonts, the KakaoTalk binary, the launcher, and desktop integration, failing on any miss.
- **Docker image and regression harness** — a daily-driver image that persists login and chat
  data outside the image, plus a clean-container harness that reruns the whole `install.sh`.

## Verified environment

| Item | Value |
|---|---|
| OS | Ubuntu 24.04.4 LTS (amd64 + i386) |
| Wine | WineHQ staging 11.15, `/opt/wine-staging/bin/wine` |
| Windows mode | Windows 10, win64 prefix |
| winetricks | `cjkfonts` only |
| Gecko / Mono | 2.47.4 (x86, x86_64) / 11.2.0 (x86) |
| KakaoTalk | 26.7.1.5263 |
| Default prefix | `~/.wine-kakaotalk-clean` |

These versions are a **known-good reference point, not a hard pin** (verified 2026-08-20).
WineHQ staging is a rolling package and the KakaoTalk CDN serves newer installers over time, so
later versions are expected to work.

## Quick start

```bash
git clone https://github.com/messy-snail/ubuntu-kakaotalk.git
cd ubuntu-kakaotalk
./install.sh
```

The KakaoTalk installer, Wine Gecko/Mono, and `cjkfonts` are downloaded for you. The only
things you need up front are apt packages — WineHQ staging, winetricks, and the `fonts-nanum`
family. Those need `sudo`, so the script never installs them on your behalf: it prints the exact
commands and exits, and you rerun `./install.sh` afterwards. The full list and procedure live in
[`KAKAOTALK_WINE_INSTALL.md`](./KAKAOTALK_WINE_INSTALL.md) (Korean).

The Docker path has no such split. `install.sh` runs during the image build, so the apt packages
and KakaoTalk itself are all prepared inside the image.

Run it:

```bash
~/.local/bin/kakaotalk-wine
```

Searching for `KakaoTalk` in your desktop application menu launches the same script.

## Required in-app setting

> [!IMPORTANT]
> After signing in, you must select this inside KakaoTalk:
>
> ```text
> Settings → Display → Font → 나눔고딕 (NanumGothic)
> ```
>
> It is the `Display` tab, not `Settings → Chat`. Without it, Korean text in the message input
> box can render as garbage or freeze Wine right after you type, even when the chat body looks
> fine.

## Docker

```bash
./docker/kakaotalk.sh build
./docker/kakaotalk.sh run
```

The first run copies the image's prefix template to `~/.local/share/kakaotalk-docker` and every
later run reuses that directory, so your login session and chat data survive a rebuild. The
**required in-app setting** above applies to Docker as well.

Management commands (`shell`, `update`, `clean`) and host integration details are in
[`docker/README.md`](./docker/README.md) (Korean).

## Regression check

```bash
./test/docker-verify.sh build
./test/docker-verify.sh run
```

Runs the root `install.sh` from scratch in a clean Ubuntu 24.04 container to confirm the docs and
the automation still describe the same procedure. It does not mount your host Wine prefix. See
[`test/README.md`](./test/README.md) (Korean) for the checks and limitations.

## Environment variables

| Name | Default | Purpose |
|---|---|---|
| `KAKAOTALK_PREFIX` | `$HOME/.wine-kakaotalk-clean` | Wine prefix used to install and run |
| `KAKAOTALK_CACHE` | `$HOME/.cache/kakaotalk-installer` | KakaoTalk installer cache |
| `KAKAOTALK_INSTALL_DESKTOP` | `1` | Set to `0` to skip the icon and desktop entries |
| `KAKAOTALK_DOCKER_DATA` | `$HOME/.local/share/kakaotalk-docker` | Docker persistent data path |

Pass the same value to both install and launch to keep prefixes separate.

```bash
KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-test" ./install.sh
KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-test" ~/.local/bin/kakaotalk-wine
```

## Documentation

| Document | Read it when |
|---|---|
| [`KAKAOTALK_WINE_INSTALL.md`](./KAKAOTALK_WINE_INSTALL.md) | Following the full procedure, `sudo` commands, and manual verification by hand |
| [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md) | Blank chat windows, broken Korean input, `c0000409`, GPU / audio / input-method problems |
| [`docker/README.md`](./docker/README.md) | Using Docker day to day, persistent data, host integration |
| [`test/README.md`](./test/README.md) | Verifying a change in a clean environment |
| [`CHANGELOG.md`](./CHANGELOG.md) | Checking what changed between releases |

Detailed documents are written in Korean. `TROUBLESHOOTING.md` also records the **hypotheses that
were ruled out** (Wine build, GPU, DLL overrides, WIC, WebView2, and more) — worth reading before
you go down the same path again.

## Letting an agent install it

You can hand this to a coding agent such as Codex or Claude Code. From the repository root:

```text
Read README.md and KAKAOTALK_WINE_INSTALL.md, then install with ./install.sh.
Show me any sudo commands before running them, and never delete an existing Wine prefix.
When you are done, report the self-check results and whether I still need to set
Display → Font → 나눔고딕.
```

## Contributing

Issues and pull requests are welcome. Bug reports narrow down much faster with this attached:

```bash
/opt/wine-staging/bin/wine --version
cat "${KAKAOTALK_PREFIX:-$HOME/.wine-kakaotalk-clean}/winetricks.log"
grep -m1 '"ProductName"=' "${KAKAOTALK_PREFIX:-$HOME/.wine-kakaotalk-clean}/system.reg"
```

Commits follow [Conventional Commits](https://www.conventionalcommits.org/) and versions are
managed with [commitizen](https://commitizen-tools.github.io/commitizen/).

```bash
uv run --no-project cz commit                    # write a commit
shellcheck -x install.sh docker/*.sh test/*.sh   # same lint as CI
```

## License and notices

The scripts and documentation in this repository are released under the
[MIT License](./LICENSE).

KakaoTalk is proprietary software owned by Kakao Corp., and the related trademarks belong to
Kakao. This repository neither bundles nor redistributes KakaoTalk; it only automates downloading
it from the official CDN and installing it. It is not sponsored or endorsed by Kakao, and your
use of KakaoTalk is governed by Kakao's terms of service. Wine is a work of the
[WineHQ project](https://www.winehq.org/) under its own license.
