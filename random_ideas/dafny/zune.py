#!/usr/bin/env python3

import sys

def isLeapYear(year: int) -> bool:
    return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)

# From start of 1980 to end of 2008 is 2008 - 1980 + 1 = 29 years
# 8 leap years
# (29 - 8) * 365 + (8) * 366 = 7665 + 2928 = 10593
# So for input 10593 loops forever!
def whichYear(days: int) -> int:
    year = 1980
    while days > 365:
        print(f"year is {year}, days is {days}")
        if isLeapYear(year):
            if days > 366:
                days -= 366
                year += 1

            # this is fix
            # else:
            #    break
        else:
            days -= 365
            year += 1
    return year

if __name__ == "__main__":
    year: int = whichYear(int(sys.argv[1]))
    print(year)
