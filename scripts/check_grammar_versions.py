#!/usr/bin/env python3
"""Which upstream version each vendored tree-sitter grammar is.

For every grammar under Grammars/, compares the vendored src/grammar.json with upstream's at each
release tag (newest first) and at HEAD, through the GitHub API (`gh`) and raw.githubusercontent.com.
Prints one JSON line per grammar: the matching tag ('HEAD' when only upstream's head matches,
'unmatched' when neither does), the latest tag and release, and how many releases behind.
Exits 1 when any grammar is behind its latest release. Usage: scripts/check_grammar_versions.py [name…]
"""
import json, subprocess, re, sys, urllib.request
import os
G=os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','Grammars')+'/'
M=[ # local dir/path, repo, upstream path
('tree-sitter-bash/src','tree-sitter/tree-sitter-bash','src'),
('tree-sitter-c/src','tree-sitter/tree-sitter-c','src'),
('tree-sitter-cpp/src','tree-sitter/tree-sitter-cpp','src'),
('tree-sitter-csharp/src','tree-sitter/tree-sitter-c-sharp','src'),
('tree-sitter-css/src','tree-sitter/tree-sitter-css','src'),
('tree-sitter-dart/src','UserNobody14/tree-sitter-dart','src'),
('tree-sitter-dockerfile/src','camdencheek/tree-sitter-dockerfile','src'),
('tree-sitter-go/src','tree-sitter/tree-sitter-go','src'),
('tree-sitter-html/src','tree-sitter/tree-sitter-html','src'),
# Java is the grammar-orchard fork on Codeberg, which commits no src/grammar.json: compare its latest tag
# (codeberg.org/api/v1/repos/grammar-orchard/tree-sitter-java-orchard/tags) with Grammars/VERSIONS.md by hand.
('tree-sitter-javascript/src','tree-sitter/tree-sitter-javascript','src'),
('tree-sitter-json/src','tree-sitter/tree-sitter-json','src'),
('tree-sitter-kotlin/src','fwcd/tree-sitter-kotlin','src'),
('tree-sitter-lua/src','tree-sitter-grammars/tree-sitter-lua','src'),
('tree-sitter-markdown/tree-sitter-markdown/src','tree-sitter-grammars/tree-sitter-markdown','tree-sitter-markdown/src'),
('tree-sitter-markdown/tree-sitter-markdown-inline/src','tree-sitter-grammars/tree-sitter-markdown','tree-sitter-markdown-inline/src'),
('tree-sitter-php/php/src','tree-sitter/tree-sitter-php','php/src'),
('tree-sitter-python/src','tree-sitter/tree-sitter-python','src'),
('tree-sitter-ruby/src','tree-sitter/tree-sitter-ruby','src'),
('tree-sitter-rust/src','tree-sitter/tree-sitter-rust','src'),
('tree-sitter-scala/src','tree-sitter/tree-sitter-scala','src'),
('tree-sitter-sql/src','DerekStride/tree-sitter-sql','src'),
('tree-sitter-swift/src','alex-pinkus/tree-sitter-swift','src'),
('tree-sitter-toml/src','tree-sitter-grammars/tree-sitter-toml','src'),
('tree-sitter-typescript/typescript/src','tree-sitter/tree-sitter-typescript','typescript/src'),
('tree-sitter-typescript/tsx/src','tree-sitter/tree-sitter-typescript','tsx/src'),
('tree-sitter-xml/src','tree-sitter-grammars/tree-sitter-xml','xml/src'),
('tree-sitter-yaml/src','tree-sitter-grammars/tree-sitter-yaml','src'),
]
def gh(path):
    r=subprocess.run(['gh','api',path,'--paginate'],capture_output=True,text=True)
    if r.returncode: return None
    t=r.stdout.replace('][',',')
    return json.loads(t)
def semkey(t):
    nums=re.findall(r'\d+',t)
    return tuple(int(n) for n in nums[:4])
def raw(repo,ref,path):
    try:
        with urllib.request.urlopen(f'https://raw.githubusercontent.com/{repo}/{ref}/{path}/grammar.json',timeout=30) as f: return json.loads(f.read())
    except Exception as e: return None
out=[]
only=sys.argv[1:] 
for local,repo,up in M:
    if only and not any(o in local for o in only): continue
    mine=json.load(open(G+local+'/grammar.json'))
    tags=[t['name'] for t in (gh(f'repos/{repo}/tags?per_page=100') or [])]
    tags=sorted([t for t in tags if re.match(r'^v?\d+\.\d+',t)],key=semkey,reverse=True)
    latest=tags[0] if tags else None
    rel=gh(f'repos/{repo}/releases/latest')
    relname=rel.get('tag_name') if isinstance(rel,dict) else None
    head=raw(repo,'HEAD',up)
    match=None; behind=0
    for t in tags[:25]:
        g=raw(repo,t,up)
        if g==mine: match=t; break
        behind+=1
    atHead = head==mine
    out.append(dict(grammar=local.split('/')[0]+('/'+local.split('/')[1] if local.count('/')>1 else ''),repo=repo,vendored=match or ('HEAD' if atHead else 'unmatched'),latest_tag=latest,latest_release=relname,releases_behind=(behind if match else None),matches_head=atHead))
    print(json.dumps(out[-1]),flush=True)
# exit 1 when any grammar is behind its latest release
sys.exit(1 if any(o['releases_behind'] for o in out) else 0)
