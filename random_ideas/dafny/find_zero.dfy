predicate non_negative(a: seq<int>)
{
    forall i :: 0 <= i < |a| ==> a[i] >= 0
}

predicate successively_decreasing_by_at_most_one(a: seq<int>)
{
    forall i :: 1 <= i < |a| ==> a[i-1] - a[i] in {0, 1}
}

method FindZero(a: array?<int>) returns (index: int)
    requires a != null
    requires non_negative(a[..])
    requires successively_decreasing_by_at_most_one(a[..])
{
    var slice := a[..];
    index := 0;
    while index < a.Length
        decreases a.Length - index
        invariant index >= 0
    {
        if a[index] == 0 {
            return;
        }
        SkippingLemma(slice, index);
        index := index + a[index];
    }
    index := -1;
}

lemma SkippingLemma(a: seq<int>, j: int)
    requires non_negative(a)
    requires successively_decreasing_by_at_most_one(a)
    requires 0 <= j < |a|
    ensures forall i :: j <= i + a[j] && i < |a| ==> a[i] != 0
{
    var i := j;
    while i < j + a[j] && i < |a|
        decreases j + a[j] - i
        invariant i < |a| ==> a[j] - (i-j) <= a[i]
        invariant forall k :: j <= k < i && k < |a| ==> a[k] != 0
    {
        i := i + 1;
    }
}

method Testing()
{
    assert successively_decreasing_by_at_most_one([5, 4, 3, 2, 1]);

    // assert successively_decreasing_by_at_most_one([5, 3, 2, 1]);
    // assert !successively_decreasing_by_at_most_one([5, 3, 2, 1]);
}