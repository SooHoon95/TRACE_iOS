# claude.ai/design — TRACE 디자인 시스템 v2.1 (발굴/전시/레거시 · Pretendard 단일)

> 기존 "TRACE Design System" 프로젝트에 붙여넣어 진화시키거나 새 프로젝트로 생성. 화면이 아니라 **디자인 시스템**을 만드는 프롬프트. **폰트는 Pretendard 하나로 통일(세리프·외부폰트 금지).**

---

```
프로젝트 이름: TRACE Design System

[중요] 앱 화면이 아니라 "디자인 시스템"을 만들어줘 — 파운데이션 토큰 + 재사용 컴포넌트.
완성 화면 만들지 마. 산출물=(1) 파운데이션 (2) 컴포넌트 변형·상태 갤러리.

[폰트 규칙] 폰트는 Pretendard 단일 패밀리만 써. Fraunces 등 세리프·장식 폰트 쓰지 마.
위계는 전부 Pretendard의 weight(400~800)와 크기 대비로만 표현해.

── 컨셉 ──
TRACE = 실제 장소가 시간캡슐이 되는 여행 앱(iOS). 장소에 "사진 순간"(사진+한마디+누구와+무드)을
남기면 쌓인다. 개인 레거시(코어): 내 사진이 세월별로 켜켜이 쌓이고 그 자리에 다시 서면 과거가
"발굴"된다(10년 전 연인과→오늘 가족과). 장소 전시(집단): 모두의 사진이 큐레이션 갤러리(톱12)가
되어 원격으로 둘러보고 현장에선 AR로 발굴. 모으는 단위는 사진이 아니라 장소·방문·내 기여.

── 원칙 ── 따뜻한 에디토리얼/갤러리 미니멀(아카이브·기억의 정서). 종이 질감·넉넉한 여백·둥근 모서리·
부드러운 낮은 그림자. 네온·차가운 테크톤 지양. 두 서피스: 라이트 페이퍼(전시·순간·레거시·공유) +
웜 다크(지도·현장 AR). 둘 다 코랄/테라코타 포인트. 위계는 Pretendard weight·크기로.

── 파운데이션 토큰(그대로 유지) ──
라이트: paper0 #FFFDF8·paper50 #FBF6EC(bg)·paper100 #F4ECE0·border #EFE6D8·divider #E6D3BD
다크:  char900 #241C16·char700 #2E2823(bg)·char600 #3A322B·char500 #463D34
포인트: coral300 #F2A98E·coral500 #E8775B(accent)·coral600 #C75D43·coralWash #FDEAE2
잉크: ink900 #2A241F·ink600 #6B5F54(body)·ink500 #9C8E7E(muted)·ink400 #B6A899
무드6: 차분 #8FB0C4·활기 #E89A4F·풍경 #88B07A·맛집 #D98A6A·모험 #C77B5A·숨은곳 #9B89B5
타이포: Pretendard 단일. weight 대비로 위계 — display(800) 52/30/26/21 · body 17/15/13/11.5 ·
  eyebrow 11(대문자, 트래킹 0.16em). 세리프 없음.
스페이싱 4px(4·8·12·16·20·24·32·40). 라디우스 sm12·md16·lg20·xl26·2xl28·pill. 그림자 따뜻틴트 2~3종.

── 만들 컴포넌트 (각각 변형·상태 포함) ──
1. Button: primary(코랄)/soft/ghost, 크기3, 상태(기본·눌림·비활성), 라이트/다크
2. VibeTag 칩: 무드 6종, 선택/비선택
3. CompanionTag: 동행 칩(연인·가족·친구·혼자), 선택/비선택 — 감성 축
4. MomentCard: 한 "사진 순간" = 사진 + 한마디(굵은 Pretendard) + 동행자 + 날짜 + 장소.
   상태: 일반 / 피처링(톱) / 내 과거(레거시 표시)
5. ExhibitionTile: 한 장소의 전시 타일 = 커버사진 + 장소명 + 기여자 수 + "톱 12" 뱃지 + 내 방문 표시
6. PlacePin(지도 핀): 기억 밀도로 크기·열기, 변형(전시 있는 곳 / 내가 다녀간 곳), 웜다크
7. ExcavationMeter(현장 발굴, 웜다크): 따뜻/차가움 4단계 + 거리(m) + "발굴하기" CTA(현장서만 활성)
8. ReturnTimeline(재방문 레거시): 같은 장소의 과거 방문들을 세로 시간층으로 — 연도 + 동행자 +
   썸네일. ★이 시스템의 감성 히어로. 라이트/다크 양쪽
9. CaptureComposer(순간 남기기): 사진 프레임 + 굵은 한마디 입력 + 동행 선택 + 무드 선택 + 제출
10. IdentityCard(여행 정체성 Wrapped): 장소-인생 요약(다녀간 장소·연수·동행 구성·시그니처 칭호·
    발자취) 공유 히어로, 웜다크
11. FeaturedRibbon / TopBadge: "이 장소 전시 톱 12" 큐레이션 마커
12. Avatar · TabBar · SectionHeader: 셸 컴포넌트
13. ActivityFeedItem: "방금 남들이 남긴 순간" 피드 행 — 작은 썸네일+장소+동행+시간(홈 활동/FOMO용)
14. PlacePromptCard: "내 주변 남길 자리" 카드 — 장소명+거리+"너도 남겨" CTA(claiming 유도)
15. JoinFeedback: 남긴 직후 "이 장소에 합류했어" 합류 피드백(토스트/배지/마크 박히는 연출)

── 산출물 형식 ──
A) Foundations: 컬러 스와치(역할 라벨)·Pretendard 타이포 스펙시먼·스페이싱/라디우스/그림자 스케일
B) Components: 컴포넌트별 변형·상태 갤러리, 라이트 페이퍼/웜 다크 둘 다. 재사용 파라미터화.
완성 앱 화면은 만들지 말 것. 폰트는 Pretendard만.
```

---

**팁:** Foundations → 원자(Button·VibeTag·CompanionTag·뱃지) → MomentCard·ExhibitionTile·PlacePin → ExcavationMeter·ReturnTimeline·IdentityCard 순. **ReturnTimeline·IdentityCard가 감성 핵심.**
