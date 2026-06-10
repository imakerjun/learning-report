# AGENT.md — 헤르메스 에이전트 실행 계약서

이 문서는 **에이전트가 따르는 절차서**다. 챌린지 참여자가 디스코드에서
"이 템플릿으로 내 학습 리포트 만들고 배포해서 스크린샷 보여줘"라고 요청하면,
에이전트는 아래 절차를 **순서대로** 수행한다.

> 핵심 원칙: 에이전트는 **데이터만 깔고, 해석은 사람에게 돌려준다.**
> `reflection.user_answer`는 절대 채우지 않는다. 질문만 던진다.
> 이것이 "Read LLM"이 아니라 "Read Less with LLM"이다.

---

## 절차 (6단계)

### 1. 저장소 클론
```bash
git clone https://github.com/imakerjun/learning-report.git
cd learning-report
```

### 2. 참여자 학습 데이터 분석 → 토픽 빈도 추출

참여자의 "학습 활동"이 남은 곳을 찾아 토픽별 등장 빈도를 센다. 출처 후보:
- 참여자의 작업 저장소 git 로그 (`git log --since`, 커밋 메시지·변경 파일 경로)
- 대화·메모·노트 텍스트 파일
- 학습 일지 / outbox 기록

추출 방법:
1. **이번주(current_week)** 와 **직전 N주(기본 4주)** 구간을 나눈다.
2. 참여자에게 의미 있는 **토픽 키워드 6~10개**를 정한다.
   - 키워드는 가능하면 **참여자 본인이 먼저 적게** 한다. 그 목록과 데이터에서
     실제로 많이 나온 키워드의 **차이 자체가 학습 신호**다.
3. 각 토픽의 `current`(이번주 빈도)와 `baseline_avg`(직전 N주 평균)를 센다.
4. 가능하면 주차별 `trend` 배열(최근 5개 값)도 만든다 → 스파크라인에 쓰임.

### 3. `data/report.json` 생성 (덮어쓰기)

아래 스키마로 `data/report.json`을 쓴다. index.html이 이 파일을 **자동으로**
먼저 읽는다(없으면 sample.json fallback). 형식은 `data/sample.json` 참고.

```json
{
  "meta": {
    "owner": "참여자 이름",
    "current_week": "2026-W23",
    "baseline_label": "직전 4주 평균",
    "baseline_weeks": 4,
    "generated_at": "2026-06-10",
    "source": "데이터를 어디서 뽑았는지 한 줄"
  },
  "signals": {
    "learning_strength": { "value": 0.0-1.0, "label": "강함|보통|약함", "delta": 베이스라인대비증감, "hint": "한 줄" },
    "weekly_change": { "value": 0.0-1.0, "hint": "토픽 분포 이동량 (0=정지, 1=완전이동)" },
    "new_topics": 정수,
    "faded_topics": 정수
  },
  "topics": [
    { "name": "토픽명", "current": 정수, "baseline_avg": 정수, "trend": [수,수,수,수,수] }
  ],
  "reflection": {
    "agent_question": "이번주 변화 중 사람이 직접 답해야 할 한 가지 질문",
    "user_answer": ""
  }
}
```

**필드 산출 가이드**
- `weekly_change`: 이번주 토픽 분포 벡터와 베이스라인 분포 벡터의 거리(0~1 정규화). 어림값이어도 됨.
- `new_topics`: `baseline_avg == 0 && current > 0`인 토픽 수.
- `faded_topics`: `current == 0 && baseline_avg > 0`인 토픽 수. **가장 흥미로운 신호.**
- `agent_question`: 보통 **사라졌거나 급변한 토픽**을 짚어 "의도한 전환인가, 놓친 부분인가?"를 묻는다.
- `user_answer`: **반드시 빈 문자열 `""`로 둔다.** 에이전트가 채우면 실험 자체가 무의미해진다.

### 4. 정적 서버 실행
```bash
python3 -m http.server 8080
# (백그라운드로 띄우거나 별도 세션에서)
```

### 5. trycloudflare 터널 노출
```bash
cloudflared tunnel --url http://localhost:8080
# 출력된 https://<random>.trycloudflare.com 주소를 참여자에게 전달
# 최종 URL: https://<random>.trycloudflare.com/index.html
```
> `cloudflared`가 없으면 설치: `brew install cloudflared`

### 6. 스크린샷 캡쳐 후 전달
- 헤드리스 브라우저(playwright 등)로 `index.html`을 1280×900 이상으로 캡쳐한다.
- 페이지는 데이터 로드만으로 **클릭 없이 완성**되므로, 로드 후 ~1.2초 대기하면 막대 애니메이션이 정착된다.
- 참여자에게 **① trycloudflare URL + ② 스크린샷** 둘 다 전달한다.

---

## 체크리스트 (에이전트 self-check)

- [ ] `data/report.json`을 생성했는가 (sample.json을 수정한 게 아니라)
- [ ] `reflection.user_answer`를 빈 문자열로 두었는가
- [ ] 토픽이 6~10개인가 (너무 많으면 화면이 흐려짐)
- [ ] `faded_topics`가 1개 이상이면 그것을 `agent_question`에 반영했는가
- [ ] http로 serve했는가 (file://로는 fetch가 막힌다)
- [ ] URL + 스크린샷 둘 다 전달했는가

---

## 설계 의도 (왜 이렇게 만들었는가)

- **변화량이 본체**: 빈도 순이 아니라 `|current − baseline_avg|` 순으로 정렬된다.
  본인이 가장 못 보는 자료는 "사라진 토픽"이다.
- **에이전트는 답을 주지 않는다**: 결론을 뽑아주는 대신 질문을 되돌려준다.
  화면을 보고 사람이 직접 답을 적을 때 머리가 쓰인다.
- **단일 HTML · CDN 최소화**: clone → serve → screenshot 경로에서 실패 지점을 0에 가깝게.
  차트 라이브러리 없이 손으로 쓴 CSS + 인라인 SVG로 렌더한다.
