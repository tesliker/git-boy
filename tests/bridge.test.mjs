import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync,writeFileSync,rmSync } from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {spawn} from 'node:child_process';
import {git,review,call,httpServer} from '../integration/bridge.mjs';
test('real Git reviews pin base and HEAD, encode targets, and do not mutate repo',()=>{
 const repo=mkdtempSync(join(tmpdir(),'harbor-bridge-'));
 try{
 git(repo,['init','-b','master']);git(repo,['config','user.name','Test']);git(repo,['config','user.email','test@example.invalid']);
 writeFileSync(join(repo,'space & file.txt'),'before\n');git(repo,['add','.']);git(repo,['commit','-m','initial']);
 const base=git(repo,['rev-parse','HEAD']).trim();
 writeFileSync(join(repo,'space & file.txt'),'after\n');git(repo,['commit','-am','change']);
 const before=git(repo,['status','--porcelain=v1']);
 const r=review({repo,base,file:'space & file.txt',line:2,project:'https://agfirst.wf.lytho.us/projects/123'});
 assert.equal(r.base,base);assert.equal(new URL(r.app_url).searchParams.get('file'),'space & file.txt');assert.match(r.review_url,/127.0.0.1/);
 assert.match(call('read_review_diff',{repo,base}).diff,/\+after/);
 assert.equal(git(repo,['status','--porcelain=v1']),before);
 assert.throws(()=>review({repo,base:'--help'}));assert.throws(()=>review({repo:'relative'}));assert.throws(()=>call('push',{repo}));
 }finally{rmSync(repo,{recursive:true,force:true});}
});
test('HTTP launcher escapes user input and exposes no Git API',async()=>{
 const s=httpServer(47832);await new Promise(r=>s.once('listening',r));
 try{const r=await fetch('http://127.0.0.1:47832/review?repo=%3Cscript%3E');const body=await r.text();assert.ok(body.includes('&lt;script&gt;'));assert.ok(!body.includes('<script>'));assert.equal((await fetch('http://127.0.0.1:47832/status')).status,404);assert.equal((await fetch('http://127.0.0.1:47832/review',{method:'POST'})).status,404);}finally{await new Promise(r=>s.close(r));}
});
test('MCP stdio initialize, list, and tool errors',async()=>{
 const p=spawn(process.execPath,['integration/bridge.mjs'],{stdio:['pipe','pipe','pipe']});let output='';p.stdout.on('data',d=>output+=d);
 p.stdin.end([{id:1,method:'initialize',params:{protocolVersion:'2024-11-05'}},{id:2,method:'tools/list'},{id:3,method:'tools/call',params:{name:'prepare_code_review',arguments:{repo:'relative'}}}].map(x=>JSON.stringify({jsonrpc:'2.0',...x})).join('\n')+'\n');
 await new Promise((r,j)=>{p.on('exit',r);p.on('error',j)});
 const rows=output.trim().split('\n').map(JSON.parse);assert.equal(rows[0].result.serverInfo.name,'git-boy');assert.equal(rows[1].result.tools.length,2);assert.equal(rows[2].result.isError,true);
});
