#!/usr/bin/env python3

# pip install z3-solver
# see: https://ericpony.github.io/z3py-tutorial/guide-examples.htm

import datetime
import collections
import pprint
from typing import List

import z3


def date_range(start: datetime.date, end: datetime.date) -> List[datetime.date]:
    result: List[datetime.date] = []
    current: datetime.date = start
    while current <= end:
        result.append(current)
        current = current + datetime.timedelta(days=1)
    return result


def main():
    people = ["Noman", "Asim", "Rosna", "Dom", "Anthony", "Ivan"]
    days = date_range(start=datetime.date(2021, 12, 16), end=datetime.date(2022, 1, 2))
    choices = [z3.Int("choice_%s" % day) for day in days]
    solver = z3.Optimize()
    solver.set(priority="pareto")
    solver.set(timeout=60000)

    # (1) Constriant, choices must be valid
    for choice in choices:
        solver.add(choice >= 0)
        solver.add(choice <= len(people) - 1)

    # (2) Constriant, must not be oncall two days in a row
    for choice1, choice2 in zip(choices, choices[1:]):
        solver.add(choice1 != choice2)

    for (choice1, day1, choice2, day2, choice3, choice4) in zip(
        choices, days, choices[1:], days[1:], choices[7:], choices[8:]
    ):
        # (2a) Optimize, try not be oncall for consecutive weekends.
        if day1.isoweekday() == 6 and day2.isoweekday() == 7:
            solver.add_soft(z3.Distinct(choice1, choice2, choice3, choice4))
        # (2b) Optimize, try to ensure people are oncall on the same weekdays, e.g. always Monday, etc.
        if day1.isoweekday() not in {6, 7}:
            solver.add_soft(choice1 == choice3)

    # (2b) Optimize, try to not have oncall twice in three days.
    for choice1, choice2 in zip(choices, choices[2:]):
        solver.add_soft(choice1 != choice2)

    # (3) People constraints
    noman = people.index("Noman")
    dom = people.index("Dom")
    asim = people.index("Asim")
    noman_days = set(date_range(start=datetime.date(2021, 12, 23), end=datetime.date(2022, 1, 2)))
    for day, choice in zip(days, choices):
        if day in noman_days:
            solver.add(choice != noman)
        if day in {datetime.date(2021, 12, 18)}:
            solver.add(choice != dom)
        if day in {datetime.date(2021, 12, 24), datetime.date(2021, 12, 25)}:
            solver.add(choice != asim)

    # (4) Statutory holiday constraint
    dec_24 = [choice for (day, choice) in zip(days, choices) if day == datetime.date(2021, 12, 24)][0]
    dec_31 = [choice for (day, choice) in zip(days, choices) if day == datetime.date(2021, 12, 31)][0]
    solver.add(dec_24 != dec_31)

    # (5) Optimize, minimize difference in oncalls between people
    person_oncalls = [z3.Sum([z3.If(choice == i, 1, 0) for choice in choices]) for i in range(len(people))]
    square_diffs = [
        (person1_oncalls - person2_oncalls) ** 2
        for person1_oncalls, person2_oncalls in zip(person_oncalls, person_oncalls[1:])
    ]
    solver.minimize(z3.Sum(square_diffs))

    # (6) Optimize, minimize difference in weekend oncalls between people
    person_weekend_oncalls = [
        z3.Sum(
            [z3.If(choice == i, 1, 0) for (day, choice) in zip(days, choices) if day.isoweekday() in {6, 7}]
        )
        for i in range(len(people))
    ]
    weekend_square_diffs = [
        (person1_weekend_oncalls - person2_weekend_oncalls) ** 2
        for person1_weekend_oncalls, person2_weekend_oncalls in zip(
            person_weekend_oncalls, person_weekend_oncalls[1:]
        )
    ]
    solver.minimize(z3.Sum(weekend_square_diffs))

    print(solver.check())
    model = solver.model()
    counts = collections.defaultdict(int)
    for day, choice in zip(days, choices):
        person = people[model.evaluate(choice).as_long()]
        print("%s - %s" % (day.strftime("%a %Y-%m-%d"), person))
        counts[person] += 1
    print("-" * 80)
    pprint.pprint(counts)


if __name__ == "__main__":
    main()
