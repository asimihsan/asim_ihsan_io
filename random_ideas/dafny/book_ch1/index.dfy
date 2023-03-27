method Index(n: int) returns (i: int)
    requires 1 <= n
    ensures 0 <= i < n
{
    i := n / 2;
    // i := 0;
}

method Caller() {
    var x := Index(50);
    var y := Index(50);

    // Can't be proved because Index may be non-deterministic!
    assert x == y;
}
