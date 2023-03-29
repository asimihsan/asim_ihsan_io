method Impossible(x: int) returns (y: int)
    ensures y % 2 == 0 && y == 10 * x - 3
{
    y := Impossible(x);
}
