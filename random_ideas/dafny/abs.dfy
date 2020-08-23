method Abs(x: int) returns (y: int)
    ensures 0 <= y
    ensures x >= 0 ==> y == x
    ensures x < 0 ==> y == -x
{
    if x < 0 {
        return -x;
    } else {
        return x;
    }
}

method Testing()
{
    var v: int := Abs(3);
    assert 0 <= v;
    assert v == 3;

    var z: int := Abs(-3);
    assert z >= 0;
    assert z == 3;
}
