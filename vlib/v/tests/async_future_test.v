module main

async fn add(a int, b int) int {
	return a + b
}

fn test_async_future_basic() {
	f := future_ready[int](42)
	assert f.result == 42
}

fn test_async_fn_syntax() {
	r := await add(1, 2)
	assert r == 3
}