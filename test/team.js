const fs=require('fs'),vm=require('vm');
let s=fs.readFileSync('/Users/tarasalinas/Documents/Claude/Projects/NACBA Build/nacba-docket/index.html','utf8')
 .split('<script type="module">')[1].split('</script>')[0];
s=s.replace(/^import .*$/m,'')
   .replace(/^const sb =.*$/m,'var sb={auth:{onAuthStateChange(){},getSession:async()=>({data:{}})}};')
   .replace(/^const app = .*$/m,'var app=global.__a;')
   .replace(/^const /gm,'var ').replace(/^let /gm,'var ');
const handlers=[];
const mkEl=(attrs={})=>({innerHTML:'',textContent:'',className:'',value:'',hidden:true,
  classList:{contains:()=>false},getAttribute:k=>attrs[k]??null,
  addEventListener:(ev,fn)=>handlers.push({ev,fn,attrs}),
  querySelectorAll:()=>[],scrollIntoView(){},focus(){},remove(){}});
global.__a=mkEl(); const st={};
global.__a.querySelectorAll=sel=>{const m=/\[data-([a-z]+)\]/.exec(sel);if(!m)return[];
  const k='data-'+m[1];const a={};a[k]=k==='data-rmuser'||k==='data-role'?'x@nacba.com':'x';return[mkEl(a)];};
global.document={getElementById:i=>(st[i]=st[i]||mkEl()),querySelectorAll:()=>[],
  querySelector:()=>null,createElement:mkEl,body:{appendChild(){}}};
global.window={scrollTo(){},addEventListener(){},open:()=>null};
global.location={href:'https://x/'}; global.localStorage={getItem:()=>null,setItem(){}};
global.setTimeout=()=>{}; global.navigator={clipboard:{}}; global.confirm=()=>true;
vm.runInThisContext(s);

programs=[]; categories=[]; progCats={}; spkCats={}; links={}; uploads={}; history=[];
team=[{email:'tara@salinaslawgroup.com',role:'admin',full_name:'Tara Salinas',title:'',added_at:''},
      {email:'jd@jdl.law',role:'admin',full_name:'Jenny Doling',title:'President',added_at:''},
      {email:'staff@nacba.com',role:'coordinator',full_name:'Staff Person',title:'',added_at:''}];

function run(label, role, expect){
  myRole=role; session={user:{email:'tara@salinaslawgroup.com'}};
  view={name:'season',tab:'team',id:null,cat:null,edit:false,editSpeaker:null,creating:false};
  handlers.length=0;
  let h; try{ render(); h=global.__a.innerHTML; }
  catch(e){ console.log('  THROW '+label+' -> '+e.message); return; }
  console.log(label);
  expect.forEach(([n,ok])=>console.log((ok(h)?'    ok   ':'    FAIL ')+n));
}

run('as an administrator:','admin',[
 ['Team button in header', h=>h.includes('id="team-btn"')],
 ['all three people listed', h=>['Tara Salinas','Jenny Doling','Staff Person'].every(n=>h.includes(n))],
 ['title chip shows', h=>h.includes('>President<')],
 ['role dropdowns present', h=>(h.match(/data-role=/g)||[]).length===3],
 ['remove buttons present', h=>(h.match(/data-rmuser=/g)||[]).length===3],
 ['add form rendered', h=>h.includes('id="nu-email"')&&h.includes('id="nu-add"')],
 ['explains no email is sent', h=>h.includes('does not create an account')],
]);

// only one admin -> that admin must be protected
team=[{email:'tara@salinaslawgroup.com',role:'admin',full_name:'Tara Salinas',title:'',added_at:''},
      {email:'staff@nacba.com',role:'coordinator',full_name:'Staff Person',title:'',added_at:''}];
run('with a single administrator:','admin',[
 ['last admin cannot be removed', h=>(h.match(/data-rmuser=/g)||[]).length===1],
 ['and is labelled as such', h=>h.includes('only administrator')],
]);

run('as a coordinator:','coordinator',[
 ['no add form', h=>!h.includes('id="nu-add"')],
 ['no remove buttons', h=>!h.includes('data-rmuser=')],
 ['told who can change it', h=>h.includes('Only an administrator')],
 ['can still see the list', h=>h.includes('Staff Person')],
]);
