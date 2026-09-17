/*
 * Canonical quiz / mock-exam widget for `teach` workspaces.
 *
 * The first time a workspace needs a quiz or mock-exam widget, copy this
 * file into that workspace's own ./assets/ (e.g. assets/quiz.js) instead of
 * writing the scoring/summary logic from scratch — see ORCHESTRATION.md and
 * the "Quizzes, Flashcards & Active Recall" section of SKILL.md for why
 * that matters. Adapt the two clearly-marked spots below to the workspace
 * and leave the rest as is:
 *
 *   1. LABELS — translate every string into the workspace's output
 *      language (see "Output Language" in SKILL.md). Nothing else needs
 *      translating; all learner-facing text lives here.
 *   2. CSS — style .chip-0..chip-4, .card, .btn, .opt/.right/.wrong/.dim,
 *      .quiz-bar, .progress, .review-list, .report in the workspace's
 *      shared stylesheet (./assets/style.css or similar). Inline fallback
 *      styles are included below so the widget is still legible even
 *      before that stylesheet exists.
 *
 * Expected data shape, provided via a <script type="application/json"
 * id="quiz-data"> element in the page:
 *   { "questions": [
 *       { "cat": "Topic name", "q": "Question text",
 *         "options": ["A", "B", "C", "D"], "answer": 0,
 *         "explain": "Why the correct option is correct." }
 *   ] }
 * `cat` can be any string — categories are colored by the order they first
 * appear, so this works for any subject's taxonomy without editing code.
 *
 * Behavior this template exists to guarantee (don't drop these when
 * adapting the file — they're the reason it's bundled rather than
 * reinvented per workspace):
 *   - A visible list of exactly which questions were missed, by number and
 *     topic, once the quiz ends — not just a final score.
 *   - A compact, copyable plain-text report combining the score, the
 *     per-category breakdown, and that list, so the student can hand the
 *     result back in chat ("annota le domande sbagliate", "score + wrong
 *     question numbers", etc.) instead of reconstructing it from memory or
 *     scrolling back through the quiz. A static HTML file can't write to
 *     SOURCES.md / learning-records / SYLLABUS.md on its own — this report
 *     is the bridge back into the workspace.
 */
(function () {
  var LABELS = {
    restart: "Restart",
    correctSuffix: "correct",
    answeredSuffix: "answered",
    resultTitle: "Result",
    subjectHeader: "Topic",
    resultHeader: "Result",
    readingHeader: "Reading",
    totalLabel: "Total",
    strong: "strong",
    reinforce: "needs reinforcement",
    priority: "priority",
    reviewHeading: "Questions to review", // gets " (N)" appended
    explainLabel: "Why",
    yourAnswer: "Your answer",
    correctAnswer: "Correct",
    reportHeading: "Summary to paste into chat",
    copyButton: "Copy",
    copiedStatus: "Copied to clipboard.",
    copyFailedStatus: "Automatic copy unavailable: select the text above and use Ctrl+C.",
    footerNote: "Bring this result into the conversation so we know where to start next.",
    reportScoreLine: "Score", // "Score: 14 / 20 (70%)"
    reportWrongHeading: "Wrong questions:",
    reportNoWrong: "No mistakes."
  };

  // Reinforcement-vs-priority thresholds for the per-category verdict.
  // Adjust if a workspace's exam uses a different passing bar.
  var STRONG_PCT = 70;
  var REINFORCE_PCT = 50;

  var dataEl = document.getElementById("quiz-data");
  if (!dataEl) return;
  var data = JSON.parse(dataEl.textContent);
  var questions = data.questions || [];
  var cats = [];
  questions.forEach(function (q) {
    if (cats.indexOf(q.cat) === -1) cats.push(q.cat);
  });

  var container = document.getElementById("quiz");
  var answered = 0;
  var score = 0;
  var perCat = {};
  var wrongList = [];
  cats.forEach(function (c) { perCat[c] = { right: 0, total: 0 }; });
  questions.forEach(function (q) { perCat[q.cat].total += 1; });

  var bar = document.createElement("div");
  bar.className = "quiz-bar";
  bar.innerHTML =
    '<div class="inner">' +
    '<div class="progress"><span id="prog"></span></div>' +
    '<div class="score" id="score">0 / ' + questions.length + '</div>' +
    '<button class="btn ghost" id="reset" type="button">' + LABELS.restart + '</button>' +
    "</div>";
  document.body.insertBefore(bar, document.body.firstChild);

  var progEl = bar.querySelector("#prog");
  var scoreEl = bar.querySelector("#score");

  // Categories are colored by first-seen order rather than by matching
  // subject-specific name prefixes, so this works unchanged for any
  // taxonomy. Cycles if there are more than 5 categories.
  function catClass(cat) {
    var idx = cats.indexOf(cat);
    return "chip chip-" + (idx >= 0 ? idx % 5 : 0);
  }

  function render() {
    container.innerHTML = "";
    questions.forEach(function (q, i) {
      var wrap = document.createElement("div");
      wrap.className = "q";
      var h = document.createElement("div");
      h.innerHTML =
        '<span class="num">' + (i + 1) + " / " + questions.length + "</span> " +
        '<span class="' + catClass(q.cat) + '">' + q.cat + "</span>";
      var qt = document.createElement("div");
      qt.className = "qtext";
      qt.textContent = q.q;
      var opts = document.createElement("div");
      opts.className = "opts";
      q.options.forEach(function (text, oi) {
        var b = document.createElement("button");
        b.type = "button";
        b.className = "opt";
        b.textContent = text;
        b.addEventListener("click", function () {
          if (wrap.dataset.done) return;
          wrap.dataset.done = "1";
          answered += 1;
          var isRight = oi === q.answer;
          if (isRight) {
            score += 1;
            perCat[q.cat].right += 1;
          } else {
            wrongList.push({
              num: i + 1,
              cat: q.cat,
              q: q.q,
              chosen: text,
              correct: q.options[q.answer]
            });
          }
          opts.querySelectorAll(".opt").forEach(function (btn, bi) {
            btn.disabled = true;
            if (bi === q.answer) btn.classList.add("right");
            else if (bi === oi) btn.classList.add("wrong");
            else btn.classList.add("dim");
          });
          exp.classList.add("show");
          updateBar();
          if (answered === questions.length) showSummary();
        });
        opts.appendChild(b);
      });
      var exp = document.createElement("div");
      exp.className = "explain";
      exp.innerHTML = "<b>" + LABELS.explainLabel + ":</b> " + (q.explain || "");
      wrap.appendChild(h);
      wrap.appendChild(qt);
      wrap.appendChild(opts);
      wrap.appendChild(exp);
      container.appendChild(wrap);
    });
    updateBar();
    var old = document.getElementById("qsummary");
    if (old) old.remove();
  }

  function updateBar() {
    var pct = questions.length ? (answered / questions.length) * 100 : 0;
    progEl.style.width = pct + "%";
    scoreEl.textContent = score + " / " + questions.length + " " + LABELS.correctSuffix +
      (answered ? " (" + answered + " " + LABELS.answeredSuffix + ")" : "");
  }

  // Plain-text report combining score, per-category breakdown, and the
  // list of missed questions (number + topic) — this is what the student
  // pastes back into chat. Keep this format stable and easy to parse:
  // `teach` should be able to read it directly into a learning record
  // without needing the student to reformat anything.
  function buildReport() {
    var pct = questions.length ? Math.round((score / questions.length) * 100) : 0;
    var lines = [];
    lines.push(LABELS.reportScoreLine + ": " + score + " / " + questions.length + " (" + pct + "%)");
    cats.forEach(function (c) {
      var v = perCat[c];
      var p = v.total ? Math.round((v.right / v.total) * 100) : 0;
      lines.push(c + ": " + v.right + " / " + v.total + " (" + p + "%)");
    });
    lines.push("");
    if (wrongList.length) {
      lines.push(LABELS.reportWrongHeading);
      wrongList.forEach(function (w) {
        lines.push("#" + w.num + " [" + w.cat + "] " + w.q);
      });
    } else {
      lines.push(LABELS.reportNoWrong);
    }
    return lines.join("\n");
  }

  function legacyCopy(text) {
    try {
      var ta = document.createElement("textarea");
      ta.value = text;
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.focus();
      ta.select();
      var ok = document.execCommand("copy");
      document.body.removeChild(ta);
      return ok;
    } catch (e) {
      return false;
    }
  }

  function copyReport(text, statusEl) {
    function onOk() {
      statusEl.textContent = LABELS.copiedStatus;
      setTimeout(function () { statusEl.textContent = ""; }, 2500);
    }
    function onFail() {
      statusEl.textContent = LABELS.copyFailedStatus;
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(text).then(onOk, function () {
        if (legacyCopy(text)) onOk(); else onFail();
      });
    } else {
      if (legacyCopy(text)) onOk(); else onFail();
    }
  }

  function showSummary() {
    var s = document.createElement("div");
    s.id = "qsummary";
    s.className = "card summary";
    var rows = cats
      .map(function (c) {
        var v = perCat[c];
        var pct = v.total ? Math.round((v.right / v.total) * 100) : 0;
        var verdict = pct >= STRONG_PCT ? LABELS.strong : pct >= REINFORCE_PCT ? LABELS.reinforce : LABELS.priority;
        return "<tr><td>" + c + "</td><td>" + v.right + " / " + v.total + " (" + pct + "%)</td><td>" + verdict + "</td></tr>";
      })
      .join("");

    var reviewHtml = "";
    if (wrongList.length) {
      var items = wrongList
        .map(function (w) {
          return (
            '<li><span class="num">#' + w.num + '</span> ' +
            '<span class="' + catClass(w.cat) + '">' + w.cat + "</span>" +
            '<div class="qtext-mini">' + w.q + "</div>" +
            '<div class="muted">' + LABELS.yourAnswer + ": " + w.chosen +
            " — " + LABELS.correctAnswer + ": " + w.correct + "</div></li>"
          );
        })
        .join("");
      reviewHtml =
        "<h3>" + LABELS.reviewHeading + " (" + wrongList.length + ")</h3>" +
        '<ol class="review-list" style="padding-left:20px;margin:0 0 16px;">' + items + "</ol>";
    }

    s.innerHTML =
      "<h2>" + LABELS.resultTitle + "</h2>" +
      '<table><tr><th>' + LABELS.subjectHeader + '</th><th>' + LABELS.resultHeader +
      '</th><th>' + LABELS.readingHeader + '</th></tr>' +
      rows +
      "<tr><td><b>" + LABELS.totalLabel + "</b></td><td><b>" + score + " / " + questions.length +
      " (" + Math.round((score / questions.length) * 100) + "%)</b></td><td>—</td></tr></table>" +
      reviewHtml +
      '<div class="report">' +
      '<div class="report-head" style="display:flex;align-items:center;justify-content:space-between;gap:8px;">' +
      "<b>" + LABELS.reportHeading + "</b>" +
      '<button class="btn ghost" id="copyReport" type="button">' + LABELS.copyButton + '</button>' +
      "</div>" +
      '<textarea id="reportText" readonly rows="6" style="width:100%;box-sizing:border-box;font-family:monospace;font-size:13px;padding:8px;margin-top:6px;"></textarea>' +
      '<p class="legend" id="copyStatus"></p>' +
      "</div>" +
      '<p class="legend">' + LABELS.footerNote + '</p>';
    container.appendChild(s);

    var reportEl = s.querySelector("#reportText");
    reportEl.value = buildReport();
    reportEl.addEventListener("click", function () { reportEl.select(); });
    var statusEl = s.querySelector("#copyStatus");
    s.querySelector("#copyReport").addEventListener("click", function () {
      copyReport(reportEl.value, statusEl);
    });
  }

  bar.querySelector("#reset").addEventListener("click", function () {
    answered = 0;
    score = 0;
    wrongList = [];
    cats.forEach(function (c) { perCat[c].right = 0; });
    render();
  });

  render();
})();
