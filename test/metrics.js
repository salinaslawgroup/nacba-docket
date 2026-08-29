const fs=require('fs'),vm=require('vm'),path=require('path');
let s=fs.readFileSync(path.join(__dirname,'..','index.html'),'utf8')
 .split('<script type="module">')[1].split('</script>')[0];
s=s.replace(/^import .*$/m,'')
   .replace(/^const sb =.*$/m,'var sb={auth:{onAuthStateChange(){},getSession:async()=>({data:{}})}};')
   .replace(/^const app = .*$/m,'var app=global.__a;')
   .replace(/^const /gm,'var ').replace(/^let /gm,'var ');
const mkEl=(a={})=>({innerHTML:'',textContent:'',className:'',value:'',hidden:true,checked:false,
  classList:{contains:()=>false},getAttribute:k=>a[k]??null,addEventListener(){},
  querySelectorAll:()=>[],scrollIntoView(){},focus(){},remove(){}});
global.__a=mkEl(); const st={};
global.__a.querySelectorAll=()=>[];
global.document={getElementById:i=>(st[i]=st[i]||mkEl()),querySelectorAll:()=>[],
  querySelector:()=>null,createElement:mkEl,body:{appendChild(){}}};
global.window={scrollTo(){},addEventListener(){},open:()=>null,prompt:()=>null};
global.location={href:'https://x/'}; global.localStorage={getItem:()=>null,setItem(){}};
global.setTimeout=()=>{}; global.clearTimeout=()=>{}; global.navigator={clipboard:{}};
vm.runInThisContext(s);

session={user:{email:'t@x.com'}}; myRole='admin'; team=[]; links={}; uploads={}; history=[];
roster=[]; spkCats={}; progCats={}; categories=[]; ideas=[]; ideaCats={};
const blank={program_speakers:[],tasks:[],description:'',note:'',venue:'',location:'',
  store_url:'',recording_url:'',kind:'paid'};
programs=[
 {id:'p1',event_date:'2026-07-16',archived:false,title:'Life Settlements',...blank},
 {id:'p2',event_date:'2026-07-30',archived:false,title:'Case Law Update',...blank},
 {id:'p3',event_date:'2026-12-10',archived:false,title:'2027 Ready',...blank}];
metrics={ p1:{program_id:'p1',registrations_total:200,registrations_member:150,
  registrations_nonmember:50,live_attendees:120,gross_revenue:'4500.00',
  survey_responses:40,survey_score:'4.60',nonmember_joined:5,tech_issues:'Audio drop',
  notes:'Went well',recorded_by:'tara@salinaslawgroup.com'} };

let fails=0;
const check=(l,t)=>{console.log(l);t.forEach(([n,f])=>{let ok=false;try{ok=f();}catch(e){}
  if(!ok)fails++;console.log((ok?'    ok   ':'    FAIL ')+n);});};
const base={name:'season',id:null,edit:false,editSpeaker:null,editRoster:false,creating:false,
  cat:null,stype:null,q:'',speakerId:null,istatus:null,editIdea:null,editStats:false};

// ---- derived maths ----
const d=derive(metrics.p1);
check('derived figures:',[
 ['attendance 120/200 = 60%', ()=>d.attendance===60],
 ['per attendee 4500/120 = 37.50', ()=>d.perHead===37.5],
 ['member share 150/200 = 75%', ()=>d.memberShare===75],
 ['conversion 5/50 = 10%', ()=>d.conversion===10],
]);
const empty=derive({registrations_total:null,live_attendees:null,gross_revenue:null,
  registrations_member:null,registrations_nonmember:null,nonmember_joined:null});
check('nothing invented from blanks:',[
 ['no attendance rate', ()=>empty.attendance===null],
 ['no revenue per head', ()=>empty.perHead===null],
 ['no conversion', ()=>empty.conversion===null],
 ['blank renders as a dash', ()=>show(null)==='—' && pct(null)==='—' && money(null)==='—'],
]);
// zero must survive as zero, not become blank
check('zero is not blank:',[
 ['zero attendees shows 0', ()=>show(0)===0 || String(show(0))==='0'],
 ['0% conversion computed', ()=>derive({registrations_nonmember:50,nonmember_joined:0}).conversion===0],
]);

view={...base,tab:'analytics'}; render(); let h=global.__a.innerHTML;
check('analytics screen:',[
 ['Analytics button in header', ()=>h.includes('id="stats-btn"')],
 ['recorded count', ()=>h.includes('1 of 3')],
 ['season attendance rate', ()=>h.includes('60%')],
 ['revenue formatted', ()=>h.includes('$4,500.00')],
 ['conversion surfaced', ()=>h.includes('10%')],
 ['per-program row', ()=>h.includes('Life Settlements')],
 ['chases past programs with no stats', ()=>h.includes('Case Law Update')],
 ['future program not chased', ()=>!h.includes('2027 Ready')],
]);

view={...base,name:'detail',tab:'upcoming',id:'p1'}; render(); h=global.__a.innerHTML;
check('program page, recorded:',[
 ['stats shown', ()=>h.includes('Statistics')&&h.includes('60%')],
 ['tech problems surfaced', ()=>h.includes('Audio drop')],
 ['edit offered', ()=>h.includes('id="st-edit"')],
]);
view={...base,name:'detail',tab:'upcoming',id:'p2'}; render(); h=global.__a.innerHTML;
check('program page, nothing recorded:',[
 ['prompts for entry', ()=>h.includes('Record them')],
 ['cites 3.2', ()=>h.includes('§3.2')],
]);
view={...base,name:'detail',tab:'upcoming',id:'p1',editStats:true}; render(); h=global.__a.innerHTML;
check('entry form:',[
 ['prefilled', ()=>/id="st-reg" value="200"/.test(h)],
 ['revenue prefilled', ()=>/id="st-rev".*value="4500.00"/.test(h)],
 ['all fields', ()=>['st-mem','st-non','st-att','st-sresp','st-sscore','st-join','st-tech','st-notes']
     .every(i=>h.includes('id="'+i+'"'))],
 ['says blank is not zero', ()=>h.includes('not the same as zero')],
]);
process.exit(fails?1:0);
