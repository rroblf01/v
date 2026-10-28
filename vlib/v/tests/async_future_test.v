module main

async fn add(a int, b int) int {
	return a + b
}

fn test_async_future_basic() {
	f := future_ready[int](42)
	assert f.state.result == 42
}

fn test_async_fn_syntax() {
	f := add(1, 2)
	assert f.state.result == 3
	r := await f
	assert r == 3
}

fn worker() int {
	return 7
}

fn test_spawn_async() {
	f := spawn_async(worker)
	assert await f == 7
}