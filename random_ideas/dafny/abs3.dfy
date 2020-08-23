method Abs(x: int) returns (y: int)
    ensures y == abs(x)
{
    if x < 0 {
        y := -x;
    } else {
        y := x;
    }
}

function abs(x: int): int
{
    if x < 0 then -x else x
}

method Testing()
{
    assert abs(3) == 3;
}