newtype int32 = x | -0x80000000 <= x < 0x80000000
function double1(x: int): int
{
    x * 2
}

function double2(x: int): int
{
    x + x
}

method Testing()
{
    assert forall x: int :: double1(x) == double2(x);
}