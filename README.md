# ubuntu-kakaotalk

Ubuntu에서 카카오톡 Windows 버전을 Wine으로 돌리기 위한 설치 절차. 사람이 따라 해도 되고 Claude Code / Codex 같은 에이전트한테 통째로 맡겨도 된다.

검증 환경: Ubuntu 24.04 + KakaoTalk 26.4.0.5128 + wine-11.9 (Kron4ek).

## Clone

```bash
git clone https://github.com/messy-snail/ubuntu-kakaotalk.git
cd ubuntu-kakaotalk
```

## 설치

전체 절차는 [`KAKAOTALK_WINE_INSTALL.md`](./KAKAOTALK_WINE_INSTALL.md) 1절부터 순서대로.

## 에이전트한테 시키기

clone한 디렉토리에서 Claude Code 또는 Codex CLI를 열고 그대로 복붙.

```
KAKAOTALK_WINE_INSTALL.md를 읽고 절차대로 카카오톡을 설치해줘.
경로는 $HOME 기준, sudo 단계는 승인 받고, 끝나면 6절 성공 기준 통과 여부를 보고해.
```
