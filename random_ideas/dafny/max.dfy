method Max(a: int, b: int) returns (c: int)
    ensures c == a || c == b
    ensures c >= a
    ensures c >= b
{
    if (a > b) {
        c := a;
    } else {
        c := b;
    }
}

method Testing ()
{
    var value: int  := Max(3, 4);
    assert value >= 3;
    assert value >= 4;
    assert value == 3 || value == 4;
    
    // You can't do this with a method, but you can do this with a function.
    // assert Max(3, 4) == 3;
}