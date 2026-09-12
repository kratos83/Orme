#!/usr/bin/env python3
# Verifica che ogni livello sia risolvibile (BFS) e che start/goal non siano su rocce.
from collections import deque

# (cols, rows, sc, sr, gc, gr, rocks)
L = [
    (3,3,0,1,1,1,[]),
    (3,3,0,1,2,1,[]),
    (3,3,1,2,1,0,[]),
    (3,3,0,2,2,2,[]),
    (3,3,2,0,0,0,[]),
    (4,3,0,1,3,1,[]),
    (3,3,0,2,2,0,[]),
    (3,3,0,0,2,2,[]),
    (4,3,0,2,3,0,[]),
    (4,4,0,3,3,3,[]),
    (4,4,0,0,0,3,[]),
    (4,4,0,3,3,0,[]),
    (4,4,3,3,0,0,[]),
    (5,4,0,2,4,2,[]),
    (5,4,0,2,4,2,[(2,1),(2,2)]),
    (5,5,0,0,4,4,[(2,0),(2,1),(2,2)]),
    (5,5,0,4,4,0,[(2,2),(2,3),(2,4)]),
    (6,5,0,4,5,0,[(2,3),(2,4),(4,1),(4,2)]),
    (6,6,0,0,5,5,[(1,1),(2,1),(3,1),(4,1),(5,1),(0,3),(1,3),(2,3),(3,3),(4,3)]),
    (6,6,0,5,5,0,[(1,4),(2,4),(3,4),(4,4),(5,4),(0,2),(1,2),(2,2),(3,2),(4,2)]),
    (7,6,0,0,6,5,[(1,1),(2,1),(3,1),(4,1),(5,1),(6,1),(0,3),(1,3),(2,3),(3,3),(4,3),(5,3)]),
    (7,6,0,5,6,0,[(1,4),(2,4),(3,4),(4,4),(5,4),(6,4),(0,2),(1,2),(2,2),(3,2),(4,2),(5,2)]),
    (7,7,0,0,6,6,[(1,1),(2,1),(3,1),(4,1),(5,1),(6,1),(0,3),(1,3),(2,3),(3,3),(4,3),(5,3),(1,5),(2,5),(3,5),(4,5),(5,5),(6,5)]),
    (7,7,0,6,6,0,[(1,5),(2,5),(3,5),(4,5),(5,5),(6,5),(0,3),(1,3),(2,3),(3,3),(4,3),(5,3),(1,1),(2,1),(3,1),(4,1),(5,1),(6,1)]),
]

ok = True
for i,(c,r,sc,sr,gc,gr,rocks) in enumerate(L, 1):
    rs = set(rocks)
    problems = []
    if (sc,sr) in rs: problems.append("start su roccia")
    if (gc,gr) in rs: problems.append("goal su roccia")
    if not (0<=sc<c and 0<=sr<r): problems.append("start fuori griglia")
    if not (0<=gc<c and 0<=gr<r): problems.append("goal fuori griglia")
    # BFS
    q = deque([(sc,sr,0)]); seen={(sc,sr)}; dist=None
    while q:
        x,y,d = q.popleft()
        if (x,y)==(gc,gr): dist=d; break
        for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
            nx,ny=x+dx,y+dy
            if 0<=nx<c and 0<=ny<r and (nx,ny) not in rs and (nx,ny) not in seen:
                seen.add((nx,ny)); q.append((nx,ny,d+1))
    if dist is None: problems.append("NON risolvibile")
    status = "OK  passi minimi=%s" % dist if not problems else "  <-- " + ", ".join(problems)
    print(f"Livello {i:2}  {c}x{r}  {status}")
    if problems: ok = False

print("\nTUTTI OK" if ok else "\nCI SONO PROBLEMI")
