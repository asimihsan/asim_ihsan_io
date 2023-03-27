// s is x + y, m is max(x, y)
method MaxSum(x: int, y: int) returns (s: int, m: int)
    ensures m == x || m == y
    ensures m >= x && m >= y
    ensures s == x + y
{
    s := x + y;
    if x > y
    {
        m := x;
    }
    else
    {
        m := y;
    }
}

method Caller() {
    var s, m: int;
    s, m := MaxSum(1928, 1);
    assert s == 1929;
    assert m == 1928;
}
