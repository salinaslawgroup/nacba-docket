const fs=require('fs'),vm=require('vm'),path=require('path');
let s=fs.readFileSync(path.join(__dirname,'..','index.html'),'utf8')
 .split('<script type="module">')[1].split('</script>')[0];
s=s.replace(/^import .*$/m,'')
   .replace(/^const sb =.*$/m,'var sb={auth:{onAuthStateChange(){},getSession:async()=>({data:{}})}};')
   .replace(/^const app = .*$/m,'var app=global.__a;')
   .replace(/^const /gm,'var ').replace(/^let /gm,'var ');
const handlers=[];
const mkEl=(a={})=>({innerHTML:'',textContent:'',className:'',value:'',hidden:true,checked:false,
  classList:{contains:()=>false},getAttribute:k=>a[k]??null,
  addEventListener:(ev,fn)=>handlers.push({ev,fn,attrs:a}),
  querySelectorAll:()=>[],scrollIntoView(){},focus(){},remove(){}});
global.__a=mkEl(); const st={};
global.__a.querySelectorAll=sel=>{const m=/\[data-([a-z]+)\]/.exec(sel);if(!m)return[];
  const k='data-'+m[1];const a={};a[k]='i1';return[mkEl(a)];};
global.document={getElementById:i=>(st[i]=st[i]||mkEl()),querySelectorAll:()=>[],
  querySelector:()=>null,createElement:mkEl,body:{appendChild(){}}};
global.window={scrollTo(){},addEventListener(){},open:()=>null,prompt:()=>null};
global.location={href:'https://x/'}; global.localStorage={getItem:()=>null,setItem(){}};
global.setTimeout=()=>{}; global.clearTimeout=()=>{}; global.navigator={clipboard:{}};
global.confirm=()=>true;
vm.runInThisContext(s);

session={user:{email:'t@x.com'}}; myRole='admin'; team=[]; links={}; uploads={}; history=[];
roster=[]; spkCats={}; progCats={};
categories=[{id:'c1',name:'Student Loans'},{id:'c2',name:'Paralegal'}];
programs=[{id:'p9',event_date:'2027-02-11',kind:'paid',archived:false,title:'Scheduled One',
  description:'',note:'',venue:'',location:'',store_url:'',recording_url:'',
  program_speakers:[],tasks:[]}];
ideas=[
 {id:'i1',title:'Medical Debt After the CFPB Rule',description:'What changed.',
  rationale:'New rule',speakers_idea:'Ed Boltz',target_period:'Q1 2027',status:'idea',
  source:'Member request',suggested_by:'tara@salinaslawgroup.com',program_id:null},
 {id:'i2',title:'Already Booked',description:'',rationale:'',speakers_idea:'',
  target_period:'',status:'scheduled',source:'',suggested_by:'a@b.com',program_id:'p9'},
 {id:'i3',title:'Turned Down',description:'',rationale:'',speakers_idea:'',
  target_period:'',status:'declined',source:'',suggested_by:'a@b.com',program_id:null}];
ideaCats={i1:['c1']};

let fails=0;
const check=(label,tests)=>{console.log(label);
  tests.forEach(([n,fn])=>{let ok=false;try{ok=fn();}catch(e){}
    if(!ok)fails++;console.log((ok?'    ok   ':'    FAIL ')+n);});};
const base={name:'season',id:null,edit:false,editSpeaker:null,editRoster:false,creating:false,
            cat:null,stype:null,q:'',speakerId:null,istatus:null,editIdea:null};

view={...base,tab:'ideas'}; render(); let h=global.__a.innerHTML;
check('ideas board:',[
 ['Ideas button in header', ()=>h.includes('id="ideas-btn"')],
 ['open ideas shown', ()=>h.includes('Medical Debt After the CFPB Rule')],
 ['declined hidden by default', ()=>!h.includes('Turned Down')],
 ['scheduled shown', ()=>h.includes('Already Booked')],
 ['why + speakers surfaced', ()=>h.includes('New rule')&&h.includes('Ed Boltz')],
 ['target + source + author', ()=>h.includes('Q1 2027')&&h.includes('Member request')&&h.includes('tara')],
 ['category tag', ()=>h.includes('Student Loans')],
 ['status selector', ()=>(h.match(/data-istatus=/g)||[]).length>=2],
 ['Schedule offered when unscheduled', ()=>h.includes('data-schedule="i1"')],
 ['Open program when scheduled', ()=>h.includes('data-open="p9"')&&!h.includes('data-schedule="i2"')],
 ['scheduled date shown', ()=>/scheduled for/.test(h)],
 ['add form', ()=>h.includes('id="ni-title"')&&h.includes('id="ni-add"')],
 ['category chips are idea chips', ()=>h.includes('data-cat="idea"')],
]);

view={...base,tab:'ideas',istatus:'declined'}; render(); h=global.__a.innerHTML;
check('filtered to declined:',[
 ['declined now visible', ()=>h.includes('Turned Down')],
 ['others hidden', ()=>!h.includes('Medical Debt')],
]);

view={...base,tab:'ideas',editIdea:'i1'}; render(); h=global.__a.innerHTML;
check('editing an idea:',[
 ['form prefilled', ()=>/id="ie-title" value="Medical Debt After the CFPB Rule"/.test(h)],
 ['save and cancel', ()=>h.includes('id="ie-save"')&&h.includes('id="ie-cancel"')],
]);

view={...base,tab:'upcoming'}; render(); h=global.__a.innerHTML;
check('navigation:',[
 ['Ideas reachable from Programs', ()=>h.includes('id="ideas-btn"')],
 ['Programs still marked current', ()=>/is-here" id="programs-btn"/.test(h)],
]);
process.exit(fails?1:0);
