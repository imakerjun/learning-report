> [!IMPORTANT]
> 이 저장소는 [learning-templates](https://github.com/imakerjun/learning-templates) 모노레포로 이전되었습니다.
> 최신 버전: `learning-templates/learning-report/`

# 📊 learning-report

내 학습이 **어디로 움직이고 있는가**를 한 장으로 보는 노션 스타일 대시보드 템플릿.

빈도가 아니라 **변화량(drift)** 이 학습 신호다. 이번주 관심 토픽이 직전 기준선에서
얼마나 이동했는지 — 특히 **사라진 토픽** — 를 한눈에 보여준다.

> 인프런 AI 챌린지 5주차 라이브 실습용. 디스코드 헤르메스 에이전트가
> 참여자별 데이터를 채워 배포·캡쳐하는 흐름을 전제로 만들었다.

---

## 빠른 실행

```bash
git clone https://github.com/imakerjun/learning-report.git
cd learning-report
./serve.sh          # = python3 -m http.server 8080
# 브라우저에서 http://localhost:8080
```

기본은 `data/sample.json`(데모 데이터)으로 렌더된다.
본인 데이터로 보려면 `data/report.json`을 만들면 그쪽을 먼저 읽는다.

---

## 작동 방식

```
data/report.json  ─(없으면)→  data/sample.json
        │
        ▼
   index.html  ── 자동 fetch → 렌더 (클릭 없이 완성)
```

- **단일 HTML.** 빌드·설치 없음. 정적 서버 한 줄이면 뜬다.
- **차트 라이브러리 없음.** 손으로 쓴 CSS 막대 + 인라인 SVG 스파크라인.
- **CDN은 폰트(Pretendard) 하나뿐**, 실패해도 시스템 폰트로 graceful fallback.

이 가벼움이 핵심이다 — 에이전트가 clone → serve → screenshot 하는 경로에서
실패 지점이 거의 없다.

---

## 데이터 스키마

`data/sample.json`이 곧 스펙이다. 핵심 필드:

| 필드 | 뜻 |
|---|---|
| `topics[].current` | 이번주 토픽 등장 빈도 |
| `topics[].baseline_avg` | 직전 N주 평균 (= 기준선 점선 위치) |
| `topics[].trend` | 최근 5개 값 (스파크라인) |
| `signals.faded_topics` | 이번주 0이 된 토픽 수 — **가장 비싼 신호** |
| `reflection.agent_question` | 에이전트가 던지는 질문 |
| `reflection.user_answer` | **빈 칸. 사람이 직접 채운다.** |

토픽 상태는 `current` vs `baseline_avg`로 자동 분류된다:
`NEW · 급증 · 증가 · 유지 · 감소 · 급감 · 사라짐`.

---

## 에이전트로 만들기

디스코드 헤르메스 에이전트에게:

> "이 저장소(imakerjun/learning-report) 템플릿으로 내 학습 리포트 만들고
> 배포해서 스크린샷 보여줘"

라고 요청하면, 에이전트는 [AGENT.md](AGENT.md)의 6단계 절차를 따른다:
**클론 → 데이터 분석 → `report.json` 생성 → serve → trycloudflare 터널 → 스크린샷.**

---

## 설계 철학

세 가지 원칙으로 만들었다.

1. **변화량이 본체.** 토픽은 빈도 순이 아니라 변화량 순으로 정렬된다.
   본인이 가장 못 보는 건 "더 이상 안 하는 것"이다.
2. **에이전트는 답하지 않고 질문한다.** 결론을 뽑아주는 대신 질문을 되돌려준다.
   화면을 보고 사람이 직접 답을 적을 때만 학습이 일어난다.
3. **점진적으로 키운다.** v1은 "토픽 변화량 한 장". 이후 압축률 곡선·연결
   그래프·가설 추적을 한 장씩 더한다.

---

## 라이선스

자유롭게 fork·수정·재사용.
