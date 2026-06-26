<div align="center">

# 📝 MyMemo

**맥북 독(Dock) 옆에 붙어 다니는 할 일 · 메모 패널**

독 옆 빈 공간에 붙어 할 일과 메모를 항상 보여줍니다. 마우스를 올리면 펼쳐지고, 벗어나면 작아집니다.

![platform](https://img.shields.io/badge/platform-macOS%2014%2B-black?logo=apple)
![swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift&logoColor=white)
![ui](https://img.shields.io/badge/SwiftUI%20%2B%20AppKit-blue)
![offline](https://img.shields.io/badge/100%25-offline-success)
![license](https://img.shields.io/badge/license-Apache--2.0-blueviolet)

<img src="assets/hero.png" width="860" alt="독 옆에 붙은 MyMemo 패널" />

<sub>독 옆에 붙어 할 일과 메모를 항상 보여줍니다</sub>

</div>

---

## ✨ 펼침 / 접힘

마우스를 올리면 독 위로 부드럽게 펼쳐지고, 벗어나면 다시 작아집니다.

<div align="center">
<img src="assets/demo.gif" width="560" alt="마우스 올리면 펼쳐지고 벗어나면 접히는 데모" />
</div>

---

## 🎯 핵심 기능

| | |
|---|---|
| 🧲 **독 옆에 착** | 테두리 없는 반투명 패널이 독 옆 빈 공간에 자동으로 붙습니다. 포커스를 뺏지 않고, 모든 Space에 표시됩니다. |
| 🔍 **올리면 펼침** | 평소엔 작게, 마우스를 올리면 독 위로 커지며 전체 내용을 보여줬다가 다시 접힙니다. |
| 🖥️ **독을 따라 이동** | 멀티 모니터에서 독이 다른 화면으로 넘어가면 패널도 그 화면 독 옆으로 따라갑니다. |
| ⭐ **자동 하이라이트** | 별표(중요) → 마감 임박 순으로 상위 항목만 골라 표시 (완료 항목 제외). |
| 📐 **위치·폭 고정** | "수정하기"로 드래그·폭 조절 후 **모니터별로** 저장해 둘 수 있습니다. |
| ✍️ **별도 편집 창** | 추가 · 완료 · 별표 · 마감일 · 삭제 + 메모 편집. 메뉴바 아이콘이나 패널 더블클릭으로 열기. |
| 💾 **로컬 전용** | 완전 오프라인. 계정·클라우드 없음. 데이터는 `~/Library/Application Support/MyMemo/data.json`. |

---

## 📸 스크린샷

<table>
  <tr>
    <td align="center" width="33%">
      <img src="assets/screenshots/on-dock.png" width="100%" alt="독 옆에 붙음" /><br/>
      <sub><b>독 옆에 붙음</b><br/>독 끝 빈 공간에 자연스럽게</sub>
    </td>
    <td align="center" width="33%">
      <img src="assets/screenshots/expanded.png" width="100%" alt="펼친 모드" /><br/>
      <sub><b>펼친 모드</b><br/>마우스 올리면 할 일 + 메모</sub>
    </td>
    <td align="center" width="33%">
      <img src="assets/screenshots/compact.png" width="100%" alt="좁게 줄이면" /><br/>
      <sub><b>좁게 줄이면</b><br/>작은 칩으로 (올리면 펼침)</sub>
    </td>
  </tr>
</table>

---

## 🚀 빌드 & 실행

> **요구 사항** — macOS 14 (Sonoma) 이상 · Swift 6 (Xcode 불필요, Command Line Tools로 빌드 가능)

```bash
git clone https://github.com/hojuna/MyMemo.git
cd MyMemo

swift build                  # 빌드
bash scripts/make-app.sh     # MyMemo.app 번들 생성
open MyMemo.app              # 실행 → 메뉴바에 📝 아이콘 등장
```

핵심 로직 검증:

```bash
swift run MyMemoCheck        # HighlightRule / 영속화 단위 검증
```

---

## 🧭 사용법

1. 실행하면 **독 끝**에 작은 패널이 붙고, **메뉴바에 📝 아이콘**이 생깁니다.
2. 패널에 **마우스를 올리면** 펼쳐져 현재 할 일·메모가 보입니다.
3. 📝 아이콘 → **"메모 편집창 열기"** (또는 패널 **더블클릭**)으로 편집 창을 엽니다.
4. 할 일을 추가하고, 왼쪽 **동그라미로 완료**, **별표로 중요** 표시, 마감일을 지정합니다.
5. 중요·마감 임박 항목이 자동으로 패널에 올라옵니다.
6. 위치·폭을 바꾸려면 편집창 아래 **"패널 위치·폭 수정하기"** → 드래그·슬라이더 → **저장** (그 모니터에 고정).

---

## 🏗️ 구조

```
Sources/
  App/          @main 진입점 + AppDelegate (패널·편집창·메뉴바 와이어링)
  Core/         라이브러리 (MyMemoCore)
    Model/      Todo · Memo · AppData
    Store/      AppStore(단일 소스) · PersistenceManager · PanelLayout
    Logic/      HighlightRule (결정적 정렬·필터)
    Panel/      FloatingPanel(NSPanel) · PanelWindowController · PanelContentView
    StatusItem/ 메뉴바 상태 아이콘
    Editor/     편집 창 SwiftUI 뷰
  Check/        CLI 검증 실행 타깃
Tests/          swift-testing 단위 테스트
scripts/
  make-app.sh   .app 번들 래퍼
assets/         README용 이미지 · 데모 GIF
```

**설계 메모** — 단일 `AppStore`(`@MainActor @Observable`)가 패널과 편집창 양쪽의 유일한 소스입니다.
패널은 비활성(nonactivating) `NSPanel`이라 포커스를 뺏지 않고, 독 위치는 화면 인셋으로 감지해 따라갑니다.
펼침 시에는 독 위 레벨로 올라가 가려지지 않으며, 저장은 디바운스된 JSON 파일 쓰기(로컬 전용)입니다.

---

## 📄 라이선스

[Apache License 2.0](LICENSE) — © 2026 hojuna

자유롭게 사용·수정·배포할 수 있습니다. 자세한 내용은 `LICENSE` 파일을 참고하세요.
