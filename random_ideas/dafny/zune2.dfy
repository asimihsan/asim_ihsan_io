predicate isLeapYear(y: int) {
    y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)
}

method WhichYear(daysSince1980: int) returns (year: int) {
    var days := daysSince1980;
    year := 1980;
    while days > 365
    decreases days
    {
        if isLeapYear(year) {
            if days > 366 {
                days := days - 366;
                year := year + 1;
            } else {
                break;
            }
        } else {
            days := days - 365;
            year := year + 1;
        }
    }
}
