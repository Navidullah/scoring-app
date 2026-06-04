// Self-contained live scoreboard web page. Served at /m/:id. Polls the public
// JSON endpoint (/api/live/:id) every few seconds and re-renders — so anyone
// with the link can follow the match live in any browser, no app required.

function matchPageHtml(rawId) {
  const id = String(rawId).replace(/[^a-zA-Z0-9-]/g, '');
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
<title>Live Match — CricLive</title>
<style>
  :root { --bg1:#0A0E1A; --bg2:#0B1630; --card:rgba(255,255,255,.05); --stroke:rgba(255,255,255,.14);
    --green:#12E29A; --cyan:#22D3EE; --amber:#FFB020; --red:#FF4D6D; --hi:#F2F6FC; --mid:rgba(255,255,255,.66); --low:rgba(255,255,255,.42); }
  * { box-sizing:border-box; -webkit-tap-highlight-color:transparent; }
  body { margin:0; min-height:100vh; font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
    color:var(--hi); background:linear-gradient(160deg,var(--bg1),var(--bg2)); padding:18px; }
  .wrap { max-width:520px; margin:0 auto; }
  .brand { display:flex; align-items:center; gap:8px; margin-bottom:18px; }
  .dot { width:9px; height:9px; border-radius:50%; background:var(--green); }
  .brand b { font-size:12px; letter-spacing:1.4px;
    background:linear-gradient(90deg,var(--green),var(--cyan)); -webkit-background-clip:text; background-clip:text; color:transparent; }
  .card { background:var(--card); border:1px solid var(--stroke); border-radius:22px; padding:20px; margin-bottom:14px;
    box-shadow:0 12px 30px rgba(0,0,0,.35); }
  .live { display:inline-flex; align-items:center; gap:6px; color:var(--red); font-weight:800; font-size:11px; letter-spacing:1.4px; }
  .live .dot { background:var(--red); animation:pulse 1.2s infinite; }
  @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.3} }
  .teams { color:var(--mid); font-size:14px; margin:4px 0 8px; }
  .score { font-size:54px; font-weight:900; letter-spacing:-2px; line-height:1;
    background:linear-gradient(90deg,var(--green),var(--cyan)); -webkit-background-clip:text; background-clip:text; color:transparent; display:inline-block; }
  .overs { color:var(--mid); font-size:18px; margin-left:10px; font-weight:700; }
  .pills { margin-top:14px; display:flex; gap:8px; flex-wrap:wrap; }
  .pill { background:rgba(18,226,154,.14); border:1px solid rgba(18,226,154,.3); color:var(--green);
    border-radius:12px; padding:6px 12px; font-size:13px; font-weight:700; }
  .pill.amber { background:rgba(255,176,32,.14); border-color:rgba(255,176,32,.3); color:var(--amber); }
  .chase { margin-top:12px; background:rgba(255,176,32,.12); border:1px solid rgba(255,176,32,.3); color:var(--amber);
    border-radius:12px; padding:10px 14px; font-size:13px; font-weight:700; }
  .result { margin-top:8px; background:linear-gradient(90deg,var(--green),var(--cyan)); color:#06251A;
    border-radius:20px; padding:8px 14px; font-weight:800; font-size:14px; display:inline-block; }
  h3 { font-size:11px; letter-spacing:1px; color:var(--low); margin:0 0 10px; font-weight:800; }
  .row { display:flex; justify-content:space-between; padding:6px 0; border-bottom:1px solid rgba(255,255,255,.06); font-size:14px; }
  .row:last-child { border-bottom:0; }
  .row .name { color:var(--hi); font-weight:600; }
  .row .name.bat { color:var(--green); }
  .row .fig { color:var(--mid); font-variant-numeric:tabular-nums; }
  .inn { display:flex; justify-content:space-between; align-items:baseline; padding:8px 0; }
  .inn .t { color:var(--hi); font-weight:700; }
  .inn .s { color:var(--green); font-weight:900; font-size:18px; }
  .foot { text-align:center; color:var(--low); font-size:11px; margin-top:8px; }
  .msg { text-align:center; color:var(--mid); padding:40px 0; }
</style>
</head>
<body>
  <div class="wrap">
    <div class="brand"><span class="dot"></span><b>CRICLIVE</b></div>
    <div id="root"><div class="msg">Loading live match…</div></div>
    <div class="foot" id="foot"></div>
  </div>
<script>
  var ID = ${JSON.stringify(id)};
  function legal(b){ return b.extraType !== 'wide' && b.extraType !== 'noBall'; }
  function totalRuns(b){ return (b.runs||0) + (b.extraRuns||0); }
  function score(inn){
    var balls=(inn&&inn.balls)||[], r=0,w=0,l=0;
    for(var i=0;i<balls.length;i++){ var b=balls[i]; r+=totalRuns(b); if(b.wicket)w++; if(legal(b))l++; }
    return { runs:r, wickets:w, legal:l, overs:Math.floor(l/6)+'.'+(l%6) };
  }
  function batRow(inn, name, isStriker){
    if(!name) return '';
    var balls=inn.balls||[], runs=0,faced=0,fours=0,sixes=0;
    for(var i=0;i<balls.length;i++){ var b=balls[i]; if(b.strikerName!==name) continue; runs+=b.runs||0; if(b.extraType!=='wide')faced++; if(b.runs===4)fours++; if(b.runs===6)sixes++; }
    var sr = faced? (runs*100/faced).toFixed(1):'0.0';
    return '<div class="row"><span class="name bat">'+esc(name)+(isStriker?' *':'')+'</span><span class="fig">'+runs+' ('+faced+')  4s:'+fours+'  6s:'+sixes+'  SR '+sr+'</span></div>';
  }
  function bowlRow(inn){
    var name=inn.bowler; if(!name) return '';
    var balls=inn.balls||[], legalc=0,conc=0,wk=0;
    for(var i=0;i<balls.length;i++){ var b=balls[i]; if(b.bowlerName!==name) continue; if(legal(b))legalc++; var bc=(b.extraType==='bye'||b.extraType==='legBye')?(b.runs||0):totalRuns(b); conc+=bc; if(b.wicket&&b.wicket!=='runOut'&&b.wicket!=='retired')wk++; }
    return '<div class="row"><span class="name">'+esc(name)+'</span><span class="fig">'+(Math.floor(legalc/6)+'.'+(legalc%6))+'-'+conc+'-'+wk+'</span></div>';
  }
  function esc(s){ return String(s).replace(/[&<>"]/g, function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c];}); }
  function ballLabel(t){ return t==='tennis'?'Tennis':'Leather'; }

  function render(m){
    var inns=m.innings||[]; var cur=inns.length?inns[inns.length-1]:null;
    var done = m.status==='completed';
    var html='<div class="card">';
    html += done ? '' : '<div class="live"><span class="dot"></span>LIVE</div>';
    html += '<div class="teams">'+esc(m.team1)+' vs '+esc(m.team2)+'  ·  '+ballLabel(m.ballType)+' ball  ·  '+m.overs+' ov</div>';
    if(cur){
      var s=score(cur);
      html += '<div><span class="score">'+s.runs+'/'+s.wickets+'</span><span class="overs">'+s.overs+'/'+m.overs+' ov</span></div>';
      var crr = s.legal? (s.runs*6/s.legal).toFixed(2):'0.00';
      html += '<div class="pills"><span class="pill">CRR '+crr+'</span>';
      if(cur.target) html += '<span class="pill amber">Target '+cur.target+'</span>';
      html += '</div>';
      if(cur.target && !done){
        var need=cur.target - s.runs, ballsLeft=m.overs*6 - s.legal;
        if(need>0 && ballsLeft>0){ var rrr=(need*6/ballsLeft).toFixed(2);
          html += '<div class="chase">Need '+need+' from '+ballsLeft+' balls · RRR '+rrr+'</div>'; }
      }
    }
    if(done && m.resultText){ html += '<div class="result">'+esc(m.resultText)+'</div>'; }
    html += '</div>';

    if(cur && !done){
      html += '<div class="card"><h3>AT THE CREASE</h3>';
      html += batRow(cur, cur.striker, true) + batRow(cur, cur.nonStriker, false) + bowlRow(cur);
      html += '</div>';
    }
    if(inns.length){
      html += '<div class="card"><h3>INNINGS</h3>';
      for(var i=0;i<inns.length;i++){ var sc=score(inns[i]);
        html += '<div class="inn"><span class="t">'+esc(inns[i].battingTeam)+'</span><span class="s">'+sc.runs+'/'+sc.wickets+' <span class="overs">('+sc.overs+')</span></span></div>'; }
      html += '</div>';
    }
    document.getElementById('root').innerHTML = html;
  }

  function load(){
    fetch('/api/live/'+ID, {cache:'no-store'}).then(function(r){return r.json();}).then(function(j){
      if(!j || !j.success){ document.getElementById('root').innerHTML='<div class="msg">Match not found, or it hasn\\'t been shared live yet.</div>'; document.getElementById('foot').textContent=''; return; }
      render(j.data);
      document.getElementById('foot').textContent = 'Auto-updating · last refreshed '+new Date().toLocaleTimeString();
    }).catch(function(){ document.getElementById('foot').textContent='Reconnecting…'; });
  }
  load();
  setInterval(load, 4000);
</script>
</body>
</html>`;
}

module.exports = { matchPageHtml };
