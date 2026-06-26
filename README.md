# MyMemo

맥북 **독(Dock) 옆에 붙는** 길쭉한 플로팅 패널로 할 일과 메모를 항상 보여주는 네이티브 macOS 앱.

독 옆 빈 공간에 딱 맞춰 떠 있고, 중요한 할 일을 자동으로 골라 보여줍니다. 편집은 별도 창에서.

## 주요 기능

- **독 옆 플로팅 패널** — 테두리 없는 반투명 패널이 독 옆 빈 공간에 항상 떠 있음 (포커스 안 뺏음, 모든 Space에 표시)
- **독을 따라 이동** — 멀티 모니터에서 독이 다른 화면으로 가면 패널도 따라감
- **규칙 기반 자동 하이라이트** — 별표(중요) → 마감 임박 순으로 상위 항목만 패널에 표시 (완료 항목 제외)
- **마우스 올리면 펼쳐 보기** — 패널이 좁으면 작게 두고, 마우스를 올리면 독 위로 커지며 전체 내용 표시
- **위치·폭 수동 고정** — "수정하기"로 드래그·폭 조절 후 **모니터별로 저장**
- **별도 편집 창** — 할 일 추가/완료/별표/마감일/삭제, 메모 편집 (메뉴바 아이콘 또는 패널 더블클릭으로 열기)
- **로컬 전용** — 완전 오프라인, 계정·클라우드 없음. 데이터는 `~/Library/Application Support/MyMemo/data.json`

## 요구 사항

- macOS 14 (Sonoma) 이상
- Swift 6 / Swift Package Manager (Xcode 불필요, Command Line Tools로 빌드 가능)

## 빌드 & 실행

```bash
swift build                  # 빌드
bash scripts/make-app.sh     # MyMemo.app 번들 생성
open MyMemo.app              # 실행 (메뉴바에 아이콘이 나타남)
```

로직 검증:

```bash
swift run MyMemoCheck        # HighlightRule / 영속화 단위 검증
```

## 구조

```
Sources/
  App/        @main 진입점 + AppDelegate (패널·편집창·메뉴바 와이어링)
  Core/       라이브러리 (MyMemoCore)
    Model/    Todo, Memo, AppData
    Store/    AppStore(단일 소스), PersistenceManager, PanelLayout
    Logic/    HighlightRule (결정적 정렬/필터)
    Panel/    FloatingPanel(NSPanel), PanelWindowController, PanelContentView
    StatusItem/ 메뉴바 상태 아이콘
    Editor/   편집 창 SwiftUI 뷰
  Check/      CLI 검증 실행 타깃
Tests/        swift-testing 단위 테스트
scripts/
  make-app.sh .app 번들 래퍼
```

## 라이선스

개인 프로젝트.
