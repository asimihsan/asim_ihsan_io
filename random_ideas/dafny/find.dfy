method Find(a: array<int>, key: int) returns (index: int)
    ensures index >= 0 ==> index < a.Length && a[index] == key
    ensures index < 0 ==> forall k :: 0 <= k < a.Length ==> a[k] != key
{
    index := 0;
    while index < a.Length
        decreases a.Length - index
        invariant 0 <= index <= a.Length
        invariant forall k :: 0 <= k < index ==> a[k] != key
    {
        if a[index] == key {
            return;
        }
        index := index + 1;
    }
    index := -1;
}