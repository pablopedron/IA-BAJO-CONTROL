const fs=require('fs'), vm=require('vm');
function el(){return {textContent:"",innerHTML:"",disabled:false,children:[],attrs:{},handlers:{},addEventListener(t,f){this.handlers[t]=f},replaceChildren(...c){this.children=c;this.textContent=c.map(x=>x.textContent).join("|")},setAttribute(k,v){this.attrs[k]=v}}}
async function run(file, mode){
  const boton=el(), salida=el();
  const doc={querySelector:s=>s==="#cargar"?boton:salida,createElement:()=>el()};
  const fetchMock=async()=>{ if(mode==="200") return {ok:true,status:200,json:async()=>({title:"T",body:"B"})};
    if(mode==="500") return {ok:false,status:500,json:async()=>({})}; throw new TypeError("fail")};
  const code=fs.readFileSync(file,'utf8');
  const ctx={document:doc,fetch:fetchMock,console:{error(){}},Math,setTimeout,clearTimeout,AbortController,Error,TypeError};
  try{ vm.runInNewContext(code,ctx);}catch(e){return "no se ejecuta: "+e.name}
  try{ await boton.handlers.click(); await new Promise(r=>setTimeout(r,50)); }catch(e){return "excepción: "+e.message}
  return `salida="${salida.textContent||salida.innerHTML}" boton.disabled=${boton.disabled}`;
}
(async()=>{for(const f of process.argv.slice(2)){for(const m of ["200","500"]) console.log(f,m,"->",await run(f,m));}})();
