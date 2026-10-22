import { execFileSync } from 'node:child_process';
import { createInterface } from 'node:readline';
import { createServer } from 'node:http';
import { resolve, isAbsolute } from 'node:path';
import { realpathSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
export function git(repo, args) {
  return execFileSync(process.platform==='win32'?'git.exe':'/usr/bin/git', ['--no-pager', '-C', repo, ...args], {encoding:'utf8',maxBuffer:16*1024*1024,timeout:20000,env:{...process.env,GIT_TERMINAL_PROMPT:'0',GIT_OPTIONAL_LOCKS:'0'}});
}
export function review(args) {
  if (!isAbsolute(args.repo ?? '')) throw Error('repo must be an absolute local path');
  const repo = realpathSync(git(args.repo,['rev-parse','--show-toplevel']).trim());
  const head = git(repo,['rev-parse','HEAD']).trim();
  let base;
  if (args.base) {
    if (args.base.startsWith('-')) throw Error('Invalid base');
    base = git(repo,['rev-parse','--verify','--end-of-options',args.base+'^{commit}']).trim();
  }
  const status = git(repo,['status','--porcelain=v1','-z','--untracked-files=all']);
  const url = new URL('gitboy://review'); url.searchParams.set('repo',repo); url.searchParams.set('head',head);
  if (base) url.searchParams.set('base',base);
  for (const key of ['file','line','project']) if(args[key] !== undefined) url.searchParams.set(key,String(args[key]));
  const browser = new URL('http://127.0.0.1:47831/review'); browser.search = url.search;
  return {repo,head,base:base??null,branch:git(repo,['branch','--show-current']).trim(),status,review_url:browser.href,app_url:url.href,project_url:args.project??null,comparison:base?'merge-base to HEAD':'working tree; inspect staged and unstaged separately',note:'Local computer links. Opening does not checkout or modify files. HEAD mismatch is flagged. Working changes remain live, not an immutable snapshot.'};
}
const schema={type:'object',properties:{repo:{type:'string',description:'Absolute local repository path'},base:{type:'string',description:'Base commit or branch; resolved to a pinned commit'},file:{type:'string'},line:{type:'integer',minimum:1},project:{type:'string',description:'Canonical Lytho project URL'}},required:['repo'],additionalProperties:false};
export const tools=[{name:'prepare_code_review',description:'Prepare local Git Boy review links. Include review_url alongside Lytho and multidev links in the handoff. Does not approve, checkout, push, or publish code.',inputSchema:schema,annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:false}},{name:'read_review_diff',description:'Read a branch comparison or working/index diff for review. Untracked files are listed by prepare_code_review and must be inspected separately.',inputSchema:schema,annotations:{readOnlyHint:true,destructiveHint:false,openWorldHint:false}}];
export function call(name,args) {
  const r=review(args);
  if(name==='prepare_code_review') return r;
  if(name!=='read_review_diff') throw Error('Unknown tool');
  const common=['diff','--no-ext-diff','--no-textconv','--no-color'];
  const path=args.file?['--',args.file]:['--'];
  const diff=r.base?git(r.repo,[...common,r.base+'...'+r.head,...path]):'UNSTAGED\n'+git(r.repo,[...common,...path])+'\nSTAGED\n'+git(r.repo,[...common,'--cached',...path]);
  return {...r,diff:diff.slice(0,180000),truncated:diff.length>180000};
}
const escape=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
export function httpServer(port=47831) {
  const server=createServer((req,res)=>{
    if(req.headers.host!==`127.0.0.1:${port}` && req.headers.host!==`localhost:${port}`){res.writeHead(403);return res.end();}
    const u=new URL(req.url,'http://127.0.0.1');
    if(req.method!=='GET'||u.pathname!=='/review'){res.writeHead(404);return res.end('Not found');}
    // HTTP only renders a launcher: it never reads a repository or executes Git.
    const target=new URL('gitboy://review');target.search=u.search;
    res.writeHead(200,{'Content-Type':'text/html; charset=utf-8','Content-Security-Policy':"default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'",'X-Content-Type-Options':'nosniff','Cache-Control':'no-store','Referrer-Policy':'no-referrer'});
    res.end(`<!doctype html><meta name="viewport" content="width=device-width"><title>Git Boy Review</title><style>body{background:#101c2a;color:#e3edf4;font:17px system-ui;max-width:680px;margin:12vh auto;padding:32px}h1{font-size:38px}p{line-height:1.6;color:#acbed0}a{display:inline-block;background:#79e3b1;color:#102c23;padding:16px 24px;border-radius:10px;text-decoration:none;font-weight:700}code{word-break:break-all}</style><p>GIT BOY · CODE REVIEW</p><h1>Take a closer look.</h1><p>Open the local diff in Git Boy. This link does not switch branches, change files, or approve code.</p><p><code>${escape(u.searchParams.get('repo')??'No repository supplied')}</code></p><a href="${escape(target.href)}">Open Code Review →</a><p>Requires Git Boy on the computer holding this repository. A local link cannot open that checkout on a phone or another computer.</p>`);
  });
  server.listen(port,'127.0.0.1'); return server;
}
if(process.argv[1] && resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  if(process.argv.includes('--http')) httpServer();
  else {
    const rl=createInterface({input:process.stdin,crlfDelay:Infinity});
    rl.on('line',line=>{let m;try{m=JSON.parse(line);if(m.id===undefined)return;let result;
      if(m.method==='initialize')result={protocolVersion:m.params.protocolVersion,capabilities:{tools:{}},serverInfo:{name:'git-boy',version:'0.1.0'},instructions:'Use prepare_code_review after AI code changes. Return its review_url with canonical Lytho project and multidev links. Reviews are local and never imply approval or release authorization. Keep file and line targets where relevant.'};
      else if(m.method==='tools/list')result={tools};
      else if(m.method==='tools/call'){try{result={content:[{type:'text',text:JSON.stringify(call(m.params.name,m.params.arguments??{}))}]};}catch(e){result={isError:true,content:[{type:'text',text:e.message}]};}}
      else if(m.method==='ping')result={};
      else {process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:m.id,error:{code:-32601,message:'Method not found'}})+'\n');return;}
      process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:m.id,result})+'\n');
    }catch(e){process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:m?.id??null,error:{code:-32700,message:'Invalid request'}})+'\n');}});
  }
}
