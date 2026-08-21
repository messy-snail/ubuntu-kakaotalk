# 문제 해결

## 채팅방 백지 화면과 `Encountered an improper argument.`

가장 먼저 `winetricks.log`를 확인한다.

```bash
grep -E '^(gdiplus|riched20|vcrun2019)$' \
  "${KAKAOTALK_PREFIX:-$HOME/.wine-kakaotalk-clean}/winetricks.log"
```

하나라도 나오면 해당 prefix를 계속 수정하지 않는다. `vcrun2019`가 설치한
`mfc140u.dll`처럼 Wine 대응 built-in이 없는 파일은 `WINEDLLOVERRIDES`를 바꿔도 물리적
파일이 남아 문제를 지속시킬 수 있다. 기존 prefix는 보존하고 새 경로에 다시 설치한다.

```bash
KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-new" ./install.sh
```

## 입력창 한글 깨짐

Wine 레지스트리 설정만으로 끝나지 않는다. KakaoTalk에서 직접 다음 값을 선택한다.

```text
Settings → Display → Font → 나눔고딕
```

`Settings → Chat`이 아니라 `Display` 탭이다.

## 한글 글꼴 매핑이 깨진 prefix

Wine은 명령줄 인자를 현재 로케일 인코딩으로 해석한다. 비 UTF-8 로케일(`C`, `POSIX`)에서
설치하면 한글 레지스트리 값 이름이 깨진 채로 기록된다. v1.0.0 Docker 이미지가 여기에
해당한다.

```bash
WINEPREFIX="${KAKAOTALK_PREFIX:-$HOME/.wine-kakaotalk-clean}" \
  /opt/wine-staging/bin/wine reg query \
  'HKCU\Software\Wine\Fonts\Replacements' /v '나눔고딕'
```

`NanumGothic`이 나오지 않으면 깨진 prefix다. 깨진 값은 이런 모양으로 남는다.

```text
"k\2\30k\b\24j3 k\24\25"="NanumGothic"
```

호스트는 `./install.sh`를 다시 실행하면 멱등하게 복구된다. Docker는 이미지부터 다시
빌드해야 한다. 사용자 데이터는 이미지 밖에 있으므로 유지된다.

```bash
./docker/kakaotalk.sh build
```

깨진 값 이름 자체는 남아 있어도 무해하다. 정리하려면 prefix를 새로 만든다.

## 첫 실행 `c0000409`

`wineserver -k` 직후 첫 실행이 간헐적으로 종료될 수 있다. 저장소의 런처는 시작 후 15초
이내 비정상 종료만 최대 세 번 재시도한다.

```bash
KAKAOTALK_PREFIX="$HOME/.wine-kakaotalk-clean" ~/.local/bin/kakaotalk-wine
```

15초 이상 사용한 뒤 종료되거나 세 번 모두 실패하면 자동 재시작하지 않는다. 이때는 터미널
출력과 Wine 버전, prefix 경로를 확인한다.

## 설치 프로그램이 PC를 지원하지 않는다는 오류

prefix가 Windows 10인지 확인한다.

```bash
grep -m1 '"ProductName"=' \
  "${KAKAOTALK_PREFIX:-$HOME/.wine-kakaotalk-clean}/system.reg"
```

`Microsoft Windows 10`이 아니면 같은 prefix에 DLL verb를 추가하지 말고 새 prefix로
`install.sh`를 실행한다. installer가 오래되었을 가능성이 있으면 캐시 파일을 삭제하지 말고
이름을 바꾼 뒤 다시 다운로드한다.

## KakaoTalk.exe를 찾지 못함

Windows용 32-bit installer는 win64 prefix에서 보통 다음 경로를 사용한다.

```text
drive_c/Program Files (x86)/Kakao/KakaoTalk/KakaoTalk.exe
```

런처는 `Program Files (x86)`을 먼저 보고 `Program Files`로 폴백한다. 둘 다 없으면
installer 실행 중 X 디스플레이 오류나 서버 측 installer 거절 여부를 확인한다.

## 그래픽 오류

호스트 런처는 다음 파일이 있을 때만 NVIDIA GLVND vendor를 지정한다.

```text
/usr/share/glvnd/egl_vendor.d/10_nvidia.json
```

다른 GPU에서는 이 환경변수를 설정하지 않는다. Docker는 호스트 NVIDIA 강제 변수를 넘기지
않고 `/dev/dri`와 Mesa를 사용한다.

## Docker에서 한글 입력이 안 됨

호스트에서 `ibus-x11`과 XIM이 동작하는지 확인한다.

```bash
echo "$XMODIFIERS"
ibus version
```

래퍼는 컨테이너에 `XMODIFIERS=@im=ibus`, `LANG=C.UTF-8`, `LC_ALL=C.UTF-8`과 X 소켓을
전달한다. UTF-8 locale이 아닌 컨테이너에서는 입력 직후 Wine이 멈출 수 있다. 별도 IBus
DBus 소켓은 마운트하지 않는다.

## Docker에서 화면·GPU·오디오가 안 됨

- 화면: `DISPLAY`와 `xhost`가 필요하다. 래퍼는 현재 사용자만 잠시 허용한다.
- GPU: 존재하는 `/dev/dri/card*`, `/dev/dri/renderD*`와 실제 장치 GID를 전달한다.
- 오디오: `${XDG_RUNTIME_DIR}/pulse/native`가 없으면 경고 후 오디오 없이 실행한다.
- daemon 권한: 사용자가 직접 docker 그룹에 가입하고 다시 로그인해야 한다.

## 원인 분석 중 기각된 가설

| 가설 | 확인 결과 |
|---|---|
| Wine 빌드 자체 | Ubuntu Wine, Kron4ek, WineHQ staging 비교만으로 오류가 사라지지 않음 |
| GPU 렌더링 | GPU 설정은 일부 화면 경로에 영향을 줬지만 반복 다이얼로그의 원인은 아님 |
| DLL override | native 파일이 남은 prefix에서는 override 조합으로 복구되지 않음 |
| WIC | 이미지 코덱 경로를 바꿔도 채팅 본문 오류가 유지됨 |
| WebView2 | 광고 배너에 사용되며 채팅 본문 렌더링과 무관 |
| 로케일·스킨 경로 | 변경해도 오류가 유지됨 |
| relay에서 실패 API 탐색 | 명확한 실패 API 없이도 다이얼로그가 재현됨 |

최종적으로 winetricks DLL verb를 전혀 넣지 않은 새 prefix에서 오류창이 사라지고 채팅 본문
한글이 정상 표시됐다.

## Wine relay 진단 메모

- 일부 Kron4ek 배포 빌드는 relay 지원이 빠져 있어 `WINEDEBUG=+relay`가 출력되지 않는다.
- `RelayInclude` 필터는 `module.*` 형식을 사용한다.
- Linux `kernel.yama.ptrace_scope=1`이면 `/proc/<pid>/mem` 접근이 막혀 attach 진단이
  제한될 수 있다.
- 이 설정을 진단 편의 때문에 자동 변경하지 않는다.
