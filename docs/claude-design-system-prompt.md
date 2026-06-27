# claude.ai/design — TRACE 디자인 시스템 생성 프롬프트

> claude.ai/design에 아래 블록을 통째로 붙여넣어. (화면이 아니라 **디자인 시스템**을 만드는 프롬프트)

---

```
프로젝트 이름: TRACE Design System

[중요] 앱 화면이 아니라 "디자인 시스템"을 만들어줘. 즉 파운데이션 토큰 + 재사용 가능한
원자/분자 컴포넌트 라이브러리. 완성 화면(스크린)은 만들지 마. 산출물은 (1) 파운데이션
페이지와 (2) 각 컴포넌트의 변형·상태를 보여주는 컴포넌트 갤러리야.

── 맥락(컴포넌트가 무슨 앱을 위한 건지) ──
TRACE = 여행지의 실제 장소에 숨겨진 AR 보물(경험 카드·흔적)을 찾아 수집하면, 자동으로
나만의 여행 정체성·지도로 합쳐지는 개인 여행 도감 게임(모바일 iOS). 핵심 행동: 지도에서
보물 발견 → "따뜻/차가움"으로 접근 → 카메라 AR로 보물 획득 → 그 자리서 흔적(사진+한마디
+태그) 남기기 → 도감·정체성에 누적 → 공유.

── 디자인 원칙 ──
따뜻하고 휴머니스트한 미니멀. 종이 같은 질감, 넉넉한 여백, 둥근 모서리, 부드럽고 낮은
그림자. 네온·차가운 테크톤·과한 채도 지양. 두 가지 서피스 모드가 공존:
 • 라이트 페이퍼(크림/아이보리): 수집·도감·정체성·공유 카드 — 에디토리얼하고 자랑하고 싶은 톤
 • 웜 다크(따뜻한 차콜): 지도·헌트·AR 카메라 — 지도/카메라 위에서 대비가 좋아야 함
두 모드 모두 코랄/테라코타를 포인트로 공유.

── 파운데이션 토큰 (시작값, 더 다듬어도 됨) ──
색 — 라이트 페이퍼:
  bg #F7F4ED · surface #FFFFFF · surface-alt #FCFAF4 · border #E7E0D3
  text #24201B · text-muted #8A8276
색 — 웜 다크:
  bg #1E1B18 · surface #28241F · surface-alt #312C25 · border #3D372E
  text #F2ECE2 · text-muted #A89E8E
포인트(공통):
  coral #D9734E · coral-deep #C8623C · coral-soft #E8A07A
의미색(헌트 따뜻/차가움 — 따뜻하게 표현):
  hot #E2542F · warm #E8893B · cool #6E8CA0 · cold #51606B
희귀도 티어(따뜻 톤 유지):
  common #9A9183 · uncommon #7E9B6B · rare #D9734E · legendary #E0A93B
vibe 태그 6종(차분/활기/풍경/맛집/모험/숨은곳) 각각 부드러운 색 1개씩 배정.

타이포 — 휴머니스트. 디스플레이/헤드라인은 따뜻한 세리프(예: Fraunces 또는 Newsreader),
UI/본문은 휴머니스트 산세리프(예: Inter 또는 Hanken Grotesk).
스케일: display 34 / h1 28 / h2 22 / h3 18 / body 16 / caption 13 / micro 11 (line-height 넉넉).

스페이싱: 4px 베이스 — 4·8·12·16·24·32·48·64.
라디우스: sm 8 · md 12 · lg 16 · xl 24 · pill 999.
그림자: 따뜻하게 틴트된 낮은 그림자 2~3단계(soft/raised/overlay).
아이콘: 라인 위주, 둥근 끝, 두께 일관.

── 만들 컴포넌트 (각각 변형·상태 포함) ──
1. Button — primary(코랄)/secondary(아웃라인)/ghost, 크기 3종, 상태(기본·눌림·비활성),
   라이트/다크 양쪽.
2. VibeTag 칩 — 6종(차분/활기/풍경/맛집/모험/숨은곳), 선택/비선택.
3. RarityChip / Badge — common·uncommon·rare·legendary + "100명 중 N명" 표기.
4. CollectibleCard(도감 아이템) — 사진 썸네일 + 제목 + 희귀도 + 수집수, 상태(획득/미획득/잠김).
5. IdentityCard(여행 정체성 Wrapped) — 취향 레이더 차트 영역 + 칭호 뱃지 + 미니 발자취 지도,
   공유용 카드 프레이밍(라이트 페이퍼, 이 시스템의 히어로 컴포넌트).
6. MapPin(보물 핀) — heat 상태(차가움→뜨거움으로 크기·발광 증가), 큐레이션/유저 변형, 웜 다크.
7. WarmthIndicator(따뜻/차가움) — 4단계(hot/warm/cool/cold) + 거리(m) 표시 + "보물 꺼내기" CTA
   (활성/비활성), 웜 다크.
8. CaptureFrame / LeaveTraceInput — 사진 프레임 + 한마디 입력 + vibe 태그 선택, 흔적 남기기용.
9. Avatar, TabBar/Nav, SectionHeader 등 기본 셸 컴포넌트.

── 산출물 형식 ──
A) Foundations: 컬러 스와치(역할 라벨 포함)·타이포 스펙시먼·스페이싱/라디우스/그림자 스케일을
   한눈에 보이게.
B) Components: 위 컴포넌트들을 변형·상태별로 나열한 갤러리. 라이트 페이퍼/웜 다크 둘 다.
컴포넌트는 재사용 가능하게 파라미터화. 다시 강조 — 완성 앱 화면은 만들지 말 것.
```

---

**사용 팁:** 한 번에 다 시키면 산만해질 수 있으니, 붙여넣은 뒤 **① Foundations(토큰) 먼저 → ② Button·Tag·RarityChip 같은 원자 → ③ CollectibleCard·IdentityCard·MapPin·WarmthIndicator 순**으로 다듬으라고 이어가면 깔끔해.
