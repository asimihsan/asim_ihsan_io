lemma DistributiveLemma(a: seq<bool>, b: seq<bool>)
    decreases a, b
    ensures count(a + b) == count(a) + count(b)
{
    if a == []
    {
        assert a + b == b;
    }
    else
    {
        DistributiveLemma(a[1..], b);
        assert a + b == [a[0]] + (a[1..] + b);
    }

    // First part of building up
    // if a == []
    // {
    //     assert a + b == b;
    //     assert count(a) == 0;
    //     assert count(a + b) == count(b);
    //     assert count(a + b) == count(a) + count(b);
    // }

    // if a != [] {
    //     assert a + b == [a[0]] + (a[1..] + b);
    //     assert count(a + b) == count([a[0]]) + count(a[1..] + b);
    // }
}

function count(a: seq<bool>): nat
    decreases a
{
    if |a| == 0 then 0 else
    (if a[0] then 1 else 0) + count(a[1..])
}

method Testing()
{
    var a := [true, true, false];
    var b := [false];

    // Once you uncomment this lemma, the assertion passes. Without this lemma, Dafny can't figure out the
    // distributive property on its own. A lemma is a heavy-weight assertion.
    DistributiveLemma(a, b);

    assert count(a + b) == count(a) + count(b);
}