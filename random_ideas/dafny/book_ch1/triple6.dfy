predicate IsPositive(x: int) {
    0 <= x
}

function Average(a: int, b: int): int
    requires IsPositive(a) && IsPositive(b)
{
    (a + b) / 2
}

method Triple'(x: int) returns (r: int)
    ensures r == 3 * x
{
    if 0 <= x {
        r := Average(2 * x, 4 * x);
    } else {
        r := -Average(-2 * x, -4 * x);
    }
}

method Triple(x: int) returns (r: int)
    ensures r == 3 * x
{
    var y := 2 * x;
    r := x + y;
    assert r == 3 * x;
}

method Verifier(x: int) {
    // Fails, exprs can't call methods
    assert Triple(x) == Triple'(x);
}
