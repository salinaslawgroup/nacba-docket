// The earlier harness only called render(). It could not have caught a
// missing function that is only reached from a click handler. This one
// actually wires the DOM and fires the clicks.
const fs=require('fs'),vm=require('vm');
let s=fs.readFileSync('/Users/tarasalinas/Documents/Claude/Projects/NACBA Build/nacba-docket/index.html','utf8')
 .split('<script type="module">')[1].split('</script>')[0];
s=s.replace(/^import .*$/m,'')
   .replace(/^const sb =.*$/m,`var sb={auth:{onAuthStateChange(){},getSession:async()=>({data:{}})},
     from:()=>({select(){return this},order(){return this},eq(){return this},limit(){return this},
       then(r){return Promise.resolve({data:[],error:null}).then(r)}})};`)
   .replace(/^const app = .*$/m,'var app=global.__a;')
   .replace(/^const /gm,'var ').replace(/^let /gm,'var ');

const handlers=[];
function mkEl(attrs={}){ return {
  innerHTML:'',textContent:'',className:'',value:'',hidden:true,
  classList:{contains:()=>false},
  getAttribute:k=>attrs[k]??null,
  addEventListener:(ev,fn)=>handlers.push({ev,fn,attrs}),
  querySelectorAll:()=>[],scrollIntoView(){},focus(){},remove(){}
};}
global.__a=mkEl(); const st={};
// app.querySelectorAll returns fake elements matching whatever selector is asked for
global.__a.querySelectorAll=(sel)=>{
  const m=/\[data-([a-z]+)\]/.exec(sel);
  if(!m) return [];
  const key='data-'+m[1];
  const attrs={}; attrs[key] = key==='data-open' ? 'p1'
    : key==='data-email'||key==='data-emailprev'||key==='data-editsp' ? 'ps1'
    : key==='data-tab' ? 'upcoming' : 'x';
  return [mkEl(attrs)];
};
global.document={getElementById:i=>(st[i]=st[i]||mkEl()),querySelectorAll:()=>[],
  querySelector:()=>null,createElement:mkEl,body:{appendChild(){}}};
global.window={scrollTo(){},scrollY:0,open:()=>null,addEventListener(){},ClipboardItem:null};
global.location={href:'https://salinaslawgroup.github.io/nacba-docket/'};
global.localStorage={getItem:()=>null,setItem(){}}; global.setTimeout=(f)=>{};
global.navigator={clipboard:{writeText:async()=>{}}};
vm.runInThisContext(s);

session={user:{email:'tara@salinaslawgroup.com'}};
categories=[{id:'c1',name:'ABLI'},{id:'c2',name:'Student Loans'}];
progCats={p1:['c2']}; spkCats={s1:['c2']}; links={}; uploads={}; history=[];
programs=[{id:'p1',slug:'x',event_date:'2026-10-22',kind:'paid',title:'SLAP in a Nutshell',
  description:'d',note:'',program_speakers:[{id:'ps1',topic:'',confirmation:'confirmed',sort_order:0,
  speakers:{id:'s1',full_name:'Jenny L. Doling, Esq.',preferred_title:'',firm:'JDL',address:'',
    email:'jd@jdl.law',phone:'',pronunciation:'',headshot_location:'',bio_location:'',
    speaker_type:'debtor_attorney'},deliverables:[]}],tasks:[]}];

view={name:'season',tab:'all',id:null,cat:null,edit:false,editSpeaker:null,creating:false};
render();

let fails=0;
// handlers registered via addEventListener are already bound to their
// element, so they take the event alone
const fire=(key)=>{
  const h=handlers.filter(x=>x.attrs && x.attrs['data-'+key]!=null);
  if(!h.length){ console.log('  --   no handler for data-'+key); return; }
  try { h[0].fn({stopPropagation(){},preventDefault(){}});
        console.log('  ok   click data-'+key); }
  catch(e){ fails++; console.log('  THROW click data-'+key+' -> '+e.message); }
};

console.log('from the season dashboard:');
['open','tab'].forEach(fire);

// email buttons live on a program page, so open one first
handlers.length=0;
view={name:'detail',tab:'all',id:'p1',cat:null,edit:false,editSpeaker:null,creating:false};
links={ps1:{program_speaker_id:'ps1',token:'t'.repeat(24),open_count:0,revoked:false}};
render();
console.log('from a program page:');
['email','emailprev','editsp','back'].forEach(fire);
process.exit(fails?1:0);
