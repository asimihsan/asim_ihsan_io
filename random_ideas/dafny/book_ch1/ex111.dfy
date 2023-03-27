function F(): int {
    29
}

method M() returns (r: int)
    // need this to get b == 29 to pass
    ensures r == 29;
{
    r := 29;
}

method Caller() {
    var a := F();
    var b := M();
    assert a == 29;
    assert b == 29;
}
