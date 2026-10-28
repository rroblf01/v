module builtin

// Future represents the eventual result of an asynchronous computation.
// This is a first, synchronous placeholder used to validate the async/await
// plumbing. Real suspension is implemented in later phases.
pub struct Future[T] {
pub mut:
	result T
	done   bool
}

// future_ready creates an already-completed Future holding `value`.
pub fn future_ready[T](value T) Future[T] {
	return Future[T]{
		result: value
		done:   true
	}
}

// await is currently an identity (synchronous placeholder). It will unwrap
// Future[T] once async fn returns Future[T].
pub fn await[T](x T) T {
	return x
}