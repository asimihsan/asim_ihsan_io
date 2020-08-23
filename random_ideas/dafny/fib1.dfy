// Functions aren't code we execute in our program, they are useful for verifying code i.e. methods.
//
// If we actually ran this, e.g. fib2, it's exponential and slow!
function fib(n: nat): nat
    decreases n
{
    if n == 0 then 0 else
    if n == 1 then 1 else
                   fib(n - 1) + fib(n - 2)
}

// wrong approach
function method fib2(n: nat): nat
    decreases n
{
    if n == 0 then 0 else
    if n == 1 then 1 else
                   fib2(n - 1) + fib2(n - 2)
}

method ComputeFib(n: nat) returns (b: nat)
    ensures b == fib(n)
{
    if n == 0 {
        return 0;
    }

    var i := 1;
    var a := 0;
    b := 1;
    while i < n
        decreases n - i
        invariant i > 0

        // Note that in the last loop iteration, i become n and the loop guard condition is false. Hence the
        // invariant must be i <= n, not i < n.
        invariant i <= n

        invariant a == fib(i - 1)
        invariant b == fib(i)
    {
        a, b := b, a + b;
        i := i + 1;
    }

    // Trick Dafny into seeing the fact that i ends up being n. Dafny cannot discover the properties of the loop
    // on its own.
    //
    // True because 1) after loop ends, i >= n, and 2) loop invariant is i <= n, 3) hence i == n.
    //
    // This is still true if the loop guard is "i != n", same reason.
    //
    // Since loop invariant b == fib(i), and i == n, ==> b == fib(n), which is post-condition.
    assert i == n;
}

method Testing() {
    // this is very slow; function method is the wrong approach
    // assert fib2(60) == 1548008755920;
}