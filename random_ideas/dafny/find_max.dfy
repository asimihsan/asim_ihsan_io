method FindMax(a: array<int>) returns (i: int)
    requires a.Length > 0
    ensures 0 <= i < a.Length
    ensures forall j :: 0 <= j < a.Length ==> a[i] >= a[j]
{
    i := 0;
    var index: int := 1;
    while index < a.Length
        decreases a.Length - index
        invariant 0 <= i < a.Length
        invariant 1 <= index <= a.Length
        invariant forall k :: 0 <= k < index ==> a[i] >= a[k]
    {
        if a[index] > a[i] {
            i := index;
        }
        index := index + 1;
    }
    return i;
}
