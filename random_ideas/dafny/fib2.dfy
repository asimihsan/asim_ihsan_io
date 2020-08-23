function fib(n: nat): nat
    decreases n
{
    if n == 0 then 0 else
    if n == 1 then 1 else
                   fib(n - 1) + fib(n - 2)
}

method ComputeFib(n: nat) returns (b: nat)
    ensures b == fib(n)
{
    if n == 0 {
        return 0;
    }
    var i: int := 1;
    b := 0;
    var c: int := 1;
    while i < n
        invariant i > 0
        invariant i <= n
        invariant c == fib(i)
        invariant b == fib(i - 1)
        decreases n - i
    {
        b, c := c, b + c;
        i := i + 1;
    }

    assert i == n;
    b := c;
}