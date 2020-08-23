// See: https://github.com/byu-cs329-winter2020/hw5-formal-verification-with-dafny-egbgrace
// See: https://bitbucket.org/byucs329/byu-cs-329-lecture-notes/src/master/dafny/dafny-intro.md

datatype Student = Student(firstName: string, lastName: string, number: int, graduated: bool)

function hashCode(a: Student): int
{
    // This fails. graduated is not in equals
    // a.number % 5 + if a.graduated then 15 else 31

    // This passes.
    a.number % 5
}

function equals(a: Student, b: Student): bool
{
    a.number == b.number && a.firstName == b.firstName
}

method Main() {
    assert forall x, y: Student :: equals(x, y) ==> hashCode(x) == hashCode(y);
}