// See: https://github.com/byu-cs329-winter2020/hw5-formal-verification-with-dafny-egbgrace
// See: https://bitbucket.org/byucs329/byu-cs-329-lecture-notes/src/master/dafny/dafny-intro.md

predicate method isLeapYear(y: int) {
    y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)
}

// Does this method terminate?
// Given number of days, calculate year number starting from 1980 as base
// See: https://www.theguardian.com/technology/blog/2009/jan/01/zune-firmware-mistake
// See: https://www.cs.bgu.ac.il/~pav172/wiki.files/01-introduction.pdf
//
// From start of 1980 to end of 2008 is 2008 - 1980 + 1 = 29 years
// 8 leap years
// (29 - 8) * 365 + (8) * 366 = 7665 + 2928 = 10593
// So for input 10593 loops forever!
method WhichYear_InfiniteLoop(daysSince1980: int) returns (year: int) {
    var days := daysSince1980;
    year := 1980;
    while days > 365
    {    
        if isLeapYear(year) {
            // If 2008, it's a leap year, AND days == 366, never terminates.
            if days > 366 {
                days := days - 366;
                year := year + 1;
            }
        } else {
            days := days - 365;
            year := year + 1;
        }
    }
}

method WhichYear(daysSince1980: int) returns (year: int) {
    var days := daysSince1980;
    year := 1980;
    while days > 365
    {    
        if isLeapYear(year) {
            if days > 366 {
                days := days - 366;
                year := year + 1;
            }

            // -----------------
            // this is the fix
            // -----------------
            else
            {
                break;
            }
            // -----------------

        } else {
            days := days - 365;
            year := year + 1;
        }
    }
}

method Testing() {
    // var result1 := WhichYear_InfiniteLoop(365);
    // assert result1 == 1981;

    // var result2 := WhichYear(365);
    // assert result2 == 1981;
}