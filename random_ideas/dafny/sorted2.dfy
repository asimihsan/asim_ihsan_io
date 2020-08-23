predicate sorted2(s: seq<int>)
    decreases s
{
    0 < |s| ==> (forall i :: 0 < i < |s| ==> s[0] <= s[i]) && sorted2(s[1..])
}

function update(s: seq<int>, i: int, v: int): seq<int>
    requires 0 <= i < |s|
    ensures update(s, i, v) == s[i := v]
{
    s[..i] + [v] + s[i+1..]
}

method Testing()
{
    var s := [1, 2, 3, 4, 5];
    assert sorted2(s);
    assert s[..|s|-1] == [1, 2, 3, 4];
    assert s == s[0..] == s[..|s|] == s[0..|s|] == s[..];

    assert forall i :: 0 <=i <= |s| ==> s == s[..i] + s[i..];

    assert 5 in s;

    var p := [2, 3, 1, 0];
    assert forall i :: i in p ==> 0 <= i < |s|;

    var a := new int[3];
    a[0], a[1], a[2] := 0, 3, -1;
    var q := a[..];
    assert q == [0, 3, -1];
    
    assert 0 in a[..];
}