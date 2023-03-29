predicate sorted(a: array?<int>)
    reads a
{
    if a == null then
        false
    else
        forall j, k :: 0 <= j < k < a.Length ==> a[j] < a[k]
}

method BinarySearch(a: array?<int>, key: int) returns (index: int)
    requires a != null
    requires sorted(a)
{
    var lo: int := 0;
    var hi: int := a.Length;

    while lo < hi
        decreases hi - lo
        invariant 0 <= lo <= hi <= a.Length
        invariant forall i ::
            0 <= i < a.Length && !(lo <= i < hi) ==> a[i] != key
    {
        var mid: int := (lo + hi) / 2;
        if a[mid] < key
        {
            lo := mid + 1;
        }
        else if key < a[mid]
        {
            hi := mid;
        }
        else
        {
            return mid;
        }
    }

    return -1;
}
