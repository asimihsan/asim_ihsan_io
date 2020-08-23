method MultipleReturns(x: int, y: int) returns (more: int, less: int)
    requires y > 0
    ensures less < x
    ensures more > x
{
    more := x + y;
    less := x - y;
}