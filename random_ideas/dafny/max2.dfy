function max(a: int, b: int): int
{
    if a > b then a else b
}

method Testing() {
    assert max(3, 4) == 4;

    // But now you can't do this. Unlike methods, functions cannot appear outside of annotations or asserts.
    // But if you change 'function' to 'function method', you're allowed to.
    // var v: int := max(3, 4);
}