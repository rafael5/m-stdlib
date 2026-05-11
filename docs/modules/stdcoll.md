---
module: STDCOLL
tag: v0.2.0
phase: Phase 2
stable: stable
since: v0.2.0
synopsis: 'collections (Set, Map, Stack, Queue, Deque, Heap, OrderedDict)'
labels: ['dequeClear', 'dequePeekBack', 'dequePeekFront', 'dequePopBack', 'dequePopFront', 'dequePushBack', 'dequePushFront', 'dequeSize', 'heapClear', 'heapPeek', 'heapPeekKey', 'heapPop', 'heapPopKey', 'heapPush', 'heapSize', 'mapClear', 'mapGet', 'mapHas', 'mapNext', 'mapPut', 'mapRemove', 'mapSize', 'odictClear', 'odictFirst', 'odictGet', 'odictHas', 'odictLast', 'odictNext', 'odictPrev', 'odictPut', 'odictRemove', 'odictSize', 'queueClear', 'queuePeek', 'queuePop', 'queuePush', 'queueSize', 'setAdd', 'setClear', 'setHas', 'setNext', 'setRemove', 'setSize', 'stackClear', 'stackPeek', 'stackPop', 'stackPush', 'stackSize']
errors: []
conformance: []
see_also: []
created: 2026-05-05
last_modified: 2026-05-08
revisions: 3
doc_type: [REFERENCE]
---

# `STDCOLL` — collections

Pure-M collections for working code that needs the everyday data
structures M's built-ins do not directly model: `Set`, `Map`, `Stack`,
`Queue`, `Deque`, `Heap` (min-heap with optional payload), and an
insertion-ordered `OrderedDict`.

Every collection is a **by-reference local array** owned by the
caller. Killing the variable disposes of everything; no
process-globals are touched. This means multiple instances of the
same type coexist without fuss — they're just separate locals.

## Public API

| Type | Operations | Empty-pop / -peek |
|---|---|---|
| Set | `setAdd` `setHas` `setRemove` `setSize` `setClear` `setNext` | n/a |
| Map | `mapPut` `mapGet` `mapHas` `mapRemove` `mapSize` `mapClear` `mapNext` | n/a |
| Stack | `stackPush` `stackPop` `stackPeek` `stackSize` `stackClear` | returns `""` |
| Queue | `queuePush` `queuePop` `queuePeek` `queueSize` `queueClear` | returns `""` |
| Deque | `dequePushFront` `dequePushBack` `dequePopFront` `dequePopBack` `dequePeekFront` `dequePeekBack` `dequeSize` `dequeClear` | returns `""` |
| Heap | `heapPush` `heapPop` `heapPopKey` `heapPeek` `heapPeekKey` `heapSize` `heapClear` | returns `""` |
| OrderedDict | `odictPut` `odictGet` `odictHas` `odictRemove` `odictSize` `odictClear` `odictFirst` `odictLast` `odictNext` `odictPrev` | n/a |

Side-effect calls (push/put/add/remove/clear) are procedure-form
(`do …`). Read-form calls (get/has/peek/size/next/pop) are extrinsic
(`$$ …`). `pop` is the only side-effect call that is also extrinsic
because the value being removed is its return.

## Examples

```m
; Set — membership over an unordered collection.
NEW seen
DO setAdd^STDCOLL(.seen,"alpha")
DO setAdd^STDCOLL(.seen,"beta")
WRITE $$setHas^STDCOLL(.seen,"alpha"),!     ; 1
WRITE $$setSize^STDCOLL(.seen),!            ; 2

; Map — string-keyed dictionary with default fallback.
NEW cfg
DO mapPut^STDCOLL(.cfg,"host","localhost")
WRITE $$mapGet^STDCOLL(.cfg,"host","unset"),!   ; localhost
WRITE $$mapGet^STDCOLL(.cfg,"port","8080"),!    ; 8080  (default)

; Stack — depth-first traversal scratchpad.
NEW todo
DO stackPush^STDCOLL(.todo,"A")
DO stackPush^STDCOLL(.todo,"B")
WRITE $$stackPop^STDCOLL(.todo),!           ; B
WRITE $$stackPop^STDCOLL(.todo),!           ; A

; Queue — work pipeline.
NEW work
DO queuePush^STDCOLL(.work,"first")
DO queuePush^STDCOLL(.work,"second")
WRITE $$queuePop^STDCOLL(.work),!           ; first
WRITE $$queuePop^STDCOLL(.work),!           ; second

; Deque — sliding window with both-ends churn.
NEW win
DO dequePushBack^STDCOLL(.win,1)
DO dequePushBack^STDCOLL(.win,2)
DO dequePushBack^STDCOLL(.win,3)
DO dequePopFront^STDCOLL(.win)              ; drop oldest
WRITE $$dequePeekFront^STDCOLL(.win),!      ; 2

; Heap — priority queue (smallest key first).
NEW pq
DO heapPush^STDCOLL(.pq,3,"task A")
DO heapPush^STDCOLL(.pq,1,"task B")
DO heapPush^STDCOLL(.pq,2,"task C")
WRITE $$heapPop^STDCOLL(.pq),!              ; task B  (key 1)
WRITE $$heapPop^STDCOLL(.pq),!              ; task C  (key 2)
WRITE $$heapPop^STDCOLL(.pq),!              ; task A  (key 3)

; OrderedDict — insertion order preserved across updates.
NEW od,k
DO odictPut^STDCOLL(.od,"name","Alice")
DO odictPut^STDCOLL(.od,"role","admin")
DO odictPut^STDCOLL(.od,"name","Alice S.")  ; update — keeps slot
SET k=$$odictFirst^STDCOLL(.od)
FOR  QUIT:k=""  WRITE k,"=",$$odictGet^STDCOLL(.od,k,""),!  SET k=$$odictNext^STDCOLL(.od,k)
;   name=Alice S.
;   role=admin
```

## Behaviour

| Detail | Behaviour |
|---|---|
| Storage | By-reference local; reserved subscripts under each variable: `("v",…)`, `("n")`, `("h")`, `("t")`, `("k",…)`, `("seq",…)`, `("ord",…)`, `("nseq")`. |
| Idempotence | `setAdd` of an existing member, `mapPut` / `odictPut` of an existing key are silent updates; size does not change. `setRemove` / `mapRemove` / `odictRemove` of an absent key is a no-op. |
| Empty-string keys | `setAdd("")`, `mapPut("",…)`, `odictPut("",…)` are silent no-ops — M's `$order` cannot enumerate the empty subscript so the API would not be able to round-trip them. |
| Empty pop / peek | `stackPop` / `stackPeek`, `queuePop` / `queuePeek`, `dequePop*` / `dequePeek*`, `heapPop` / `heapPopKey` / `heapPeek` / `heapPeekKey` return `""` when the collection is empty rather than raising. Callers gate on `*Size` when they need to distinguish empty from a stored `""`. |
| Heap ordering | Min-heap on numeric keys (M's `<` operator). The optional `value` defaults to the key, so the heap-of-numbers and priority-queue-with-payload forms share one entry point. |
| OrderedDict ordering | Insertion order. Updating an existing key keeps its slot; removing skips its slot in subsequent walks. Sequence numbers (`("nseq")`) are monotonic and never reused. |
| Reset | `kill <var>` is equivalent to `*Clear`. Every entry point reads counters via `$get(…,0)` so a fresh / killed variable is indistinguishable from a `*Clear`-ed one. |

## Complexity

| Operation | Cost |
|---|---|
| Set / Map / OrderedDict by key | `O(log n)` (M B-tree subscript lookup) |
| Set / Map iteration step | `O(log n)` per `*Next` call |
| Stack push / pop / peek | `O(1)` |
| Queue / Deque push / pop / peek | `O(1)` (head/tail indices, no shifting) |
| Heap push / pop | `O(log n)` (sift-up / sift-down) |
| Heap peek / peekKey | `O(1)` |
| OrderedDict put (new) / remove | `O(log n)` |
| OrderedDict put (existing key) | `O(log n)` — value updated in place, slot retained |
| OrderedDict first / last | `O(log n)` (`$order` of the sequence index) |

## Edge cases

- **Empty input.** All `*Size` calls return 0 for an undefined,
  freshly-`new`'d, or just-`*Clear`-ed variable.
- **Heap value defaulting.** `heapPush(.h, 5)` and
  `heapPush(.h, 5, "")` are different: the first stores the key as
  the value (so `heapPop` returns `5`); the second stores `""`
  explicitly (so `heapPop` returns `""`). The default fires only
  when `value` is undefined per `$data`.
- **Heap with non-numeric keys.** `<` coerces operands to numeric;
  non-numeric strings collapse to `0`. Pass numeric keys.
- **Queue / Deque index drift.** Head and tail indices grow
  monotonically across pushes and pops. They reset to `(1, 0)`
  whenever the collection drains (the last pop kills the variable),
  so long-running queues do not accumulate state.
- **OrderedDict update vs. re-insert.** To move an existing key to
  the back, call `odictRemove` then `odictPut`. A bare `odictPut`
  preserves the original slot.
- **Stale subscripts.** `*Clear` always uses `kill <var>`, dropping
  every reserved subscript. Callers may safely re-use the same
  variable for a different collection type after a clear.

## See also

- `STDARGS` for parsed argument storage that pairs naturally with
  `mapGet` / `odictPut` for sub-command dispatch tables.
- `STDJSON` (Phase 2) for serialising / deserialising these
  collections to and from on-disk JSON once the parser ships.
