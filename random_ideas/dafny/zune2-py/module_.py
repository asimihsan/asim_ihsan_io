import sys
from typing import Callable, Any, TypeVar, NamedTuple
from math import floor
from itertools import count

import module_
import _dafny
import System_

assert "module_" == __name__
module_ = sys.modules[__name__]

class default__:
    def  __init__(self):
        pass

    def __dafnystr__(self) -> str:
        return "_module._default"
    @staticmethod
    def isLeapYear(y):
        return ((_dafny.euclidian_modulus(y, 4)) == (0)) and (((_dafny.euclidian_modulus(y, 100)) != (0)) or ((_dafny.euclidian_modulus(y, 400)) == (0)))

    @staticmethod
    def WhichYear(daysSince1980):
        year: int = int(0)
        d_0_days_: int
        d_0_days_ = daysSince1980
        year = 1980
        with _dafny.label("0"):
            while (d_0_days_) > (365):
                with _dafny.c_label("0"):
                    if module_.default__.isLeapYear(year):
                        if (d_0_days_) > (366):
                            d_0_days_ = (d_0_days_) - (366)
                            year = (year) + (1)
                        elif True:
                            raise _dafny.Break("0")
                    elif True:
                        d_0_days_ = (d_0_days_) - (365)
                        year = (year) + (1)
                    pass
            pass
        return year

