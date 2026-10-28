module builtin

// FutureState holds the shared result of an asynchronous computation.
struct FutureState[T] {
pub mut:
	result T
	done   bool
}

// Future is a handle to a shared FutureState.
pub struct Future[T] {
pub:
	state &FutureState[T]
}

// future_ready creates an already-completed Future holding `value`.
pub fn future_ready[T](value T) Future[T] {
	state := &FutureState[T]{
		result: value
		done:   true
	}
	return Future[T]{state: state}
}

// await extracts the result, blocking until it is available.
pub fn await[T](f Future[T]) T {
	for !f.state.done {
		C.usleep(1000)
	}
	return f.state.result
}

// spawn_async runs `f` in a background thread and returns a Future[T].
pub fn spawn_async[T](f fn () T) Future[T] {
	state := &FutureState[T]{}
	spawn fn [state, f] () {
		res := f()
		state.result = res
		state.done = true
	}()
	return Future[T]{state: state}
}

// sleep_async sleeps for `ms` milliseconds in a background thread.
pub fn sleep_async(ms int) Future[bool] {
	return spawn_async[bool](fn [ms] () bool {
		C.usleep(u32(ms) * 1000)
		return true
	})
}