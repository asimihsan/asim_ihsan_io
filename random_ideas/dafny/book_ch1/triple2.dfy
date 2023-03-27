method Triple(x: int) returns (r: int) {
    var y := 2 * x;
    r := x + y;
    assert r == 10 * x;
    assert r < 5;
    assert false;
    assert r == 3 * x;
}
