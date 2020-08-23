method Abs2(x: int) returns (y: int)
    requires x < 0
    ensures 0 <= y
    ensures x >= 0 ==> y == x
    ensures x < 0 ==> y == -x
{
    return -x;
}