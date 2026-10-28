# RFC: Native async/await (coroutines) for V — making V competitive for I/O-bound workloads

## Summary

I'm proposing native `async`/`await` support in V, and I already have a
working (synchronous) prototype. The goal is to let V programs handle
100K+ concurrent I/O-bound tasks (HTTP servers, database queries, file
processing) with a small number of threads, instead of being capped at
the number of OS threads.

This is a discussion first. I want to align with maintainers before
investing months in the state-machine transform.

## Why this matters for V (not just for one use case)

V is already fast and simple, which makes it attractive for servers,
tools, and infrastructure. But today, concurrency in V is `spawn`/`go`,
i.e. one OS thread per task. That caps real-world concurrency at the
number of cores (typically 4–16) and adds context-switch overhead. For
I/O-bound programs — which are most server programs — this is the main
bottleneck, not CPU.

Other languages V competes with (Go, Rust, Zig, JS) all have cooperative
coroutines. V already has the building blocks (channels, `spawn`, fast
compilation). Adding `async`/`await` would let V compete in the
server/infrastructure space without giving up simplicity.

Concrete V programs that would benefit:

- `veb` / HTTP servers: 10K+ concurrent connections on a few threads.
- `db.sqlite` / `db.pg` / `db.mysql`: non-blocking queries, connection
  pools without thread-per-request.
- File processing / log pipelines: mmap + async read, zero-copy.
- Network proxies, crawlers, chat servers, game servers.
- CLI tools that do many parallel I/O calls (fetch, copy, transform).

## What I'm proposing

```v
async fn fetch(url string) string {
    resp := await http.get(url)
    return resp.body
}

fn main() {
    f1 := fetch('https://example.com/a')
    f2 := fetch('https://example.com/b')
    // both run concurrently; await blocks only until ready
    println(await f1)
    println(await f2)
}
```

- `async fn foo() T` returns `Future[T]`.
- `await expr` suspends the coroutine without blocking the thread.
- `spawn async fn()` launches a coroutine on the scheduler.
- Cooperative scheduler (epoll/kqueue, later io_uring) drives tasks.

## Prototype status

A first, conservative prototype already exists (branch `feature/async-await`):

- `async fn` / `await expr` parse and type-check.
- `async fn` returns `Future[T]`; body is wrapped so callers get a Future.
- `Future[T]` is a shared handle, so `await` observes completion from
  background work.
- `spawn_async(f)` and `sleep_async(ms)` run work on background threads.
- `await` blocks until the Future is ready.

The prototype keeps synchronous semantics first, so it's safe to review
and adjust without risk.

## Performance goal

The bar is: **equal or better than today's synchronous/threaded model**,
not worse. Concretely:

- Concurrency ceiling: from ~cores threads to 100K+ tasks.
- Per-task memory: target < 1KB (stackless state machines, allocated on
  the heap, GC-friendly).
- No regression in single-threaded throughput. State-machine overhead
  must be measured and kept in check.
- Benchmarks will follow the `vself_speed.md` methodology (paired runs,
  instructions retired, fixed fixture).

## Roadmap (incremental, PR-sized)

1. Syntax + `Future[T]` type (done in prototype).
2. Checker: wrap async return types in `Future[T]` (done).
3. Codegen: track async functions (done).
4. State-machine transform in `vlib/v/transform` (the big one) — split
   into many small PRs, each with tests.
5. Scheduler + wakers (single-threaded executor).
6. Non-blocking I/O in `net` (epoll/kqueue, then io_uring).
7. GC safety + debugging + docs.

Each step will be a small PR with tests, not one monolithic change.

## Open questions for maintainers

1. Are you open to `async`/`await` as **language keywords**, or do you
   prefer keeping async at the library level (`vlib/x/async`)?
2. If language-level: do you want an RFC approved before any PR, or are
   incremental syntax PRs acceptable?
3. Preferred coroutine model: stackless (state machines, lower memory,
   more compiler work) vs stackful (fibers, simpler, more memory)?
4. Should io_uring be a separate backend (`-d`/flag) or integrated into
   `net` behind a flag?
5. Any constraints I should respect (e.g. "no new keywords", "keep
   compilation fast", "don't touch thirdparty")?

## What I'm asking for

- Direction on whether this aligns with V's goals.
- Feedback on the keyword/type design (`Future[T]`, `await`, `spawn`).
- Any constraints I should respect.

I'm happy to adapt the design to whatever the maintainers prefer. The
prototype is intentionally conservative (synchronous semantics first) so
it can be reviewed and adjusted without risk.

Thanks!
```