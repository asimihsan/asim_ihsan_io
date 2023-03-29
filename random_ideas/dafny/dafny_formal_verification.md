## Introduction

Dafny is a software verification tool. TODO

## How to install Dafny

-   Reference: https://github.com/dafny-lang/dafny/wiki/INSTALL
-   Go to https://github.com/dafny-lang/dafny/releases
-   Download the latest pre-release. As of 2020-08-18 it was 3.0.0 pre-release 0a.
-   Put it somewhere in your system path.
-   In VS Code, run `ext install correctnessLab.dafny-vscode`
-   Go to VS Code preferences, search for `dafny`, set the path to your Dafny binary folder and the fullpath to Mono. Then restart VS Code.
-   In order to compile to JS, install Node and the `bignumber.js` package.
-   In order to compile to Go, install Go and put `go` in your path.

## How to test Hello World

Create `hello_world.dfy`:

```
method Main() {
    print "hello, dafny\n";
    assert 10 < 2;
}
```

When you save it you should see an error "assertion violation" on line 3. Fix it:

```
method Main() {
    print "hello, dafny\n";
    assert 10 > 2;
}
```

Error should go away. At this point you've verified the program. We can compile it for Go and run it.

Now let's compile this code for Python:

```
dafny build --target py zune2.dfy
```

Output:

```
Dafny 3.0.0.20817

Dafny program verifier finished with 1 verified, 0 errors
Compiled program written to hello_world-go/src/hello_world.go
Additional code written to hello_world-go/src/dafny/dafny.go
Additional code written to hello_world-go/src/System_/System_.go
```

To run:

```
GOPATH=$(pwd)/hello_world-go go run hello_world-go/src/hello_world.go
```

Output:

```
hello, dafny
```

## How to test Fibonacci

TODO

## Official getting started guide

https://rise4fun.com/dafny/tutorialcontent/guide

-   Adding a `Testing` method for `abs`, then asserting a positive result is the same as the input, fails because
    Dafny "formats" about the body of the method. Dafny is scalable because it does not remember about the inside of
    methods, Dafny only knows about the annotations.
-   Dafny insists that method annotations, along with the types of parameters and return values, fix the behavior of
    the method.
-   After we fix `Abs` with `ensures x >= 0 ==> y == x`, notice how with an additional `Testing` case of `-3` input,
    we still can't say the result is 3. That's because we're not saying anything about negative inputs.
    -   Finally adding `ensures x < 0 ==> y == -x` fixes this.
-   After all this post-condition fixing, the post-conditions look exactly the same as the body of the method.
-   Dafny only forgets about the bodies of methods. Dafny does not forget the body of a function.
-   "Functions are never part of the final compiled program, they are just tools to help us verify our code.
    Sometimes it is convenient to use a function in real code, so one can define a function method, which can
    be called from real code."
-   `fib1.dfy`
    -   If we turned the function into a function method, this would be very slow because this method is exponential
        complexity. But we can still make a regular method and uses the function as a post-condition. This gets the
        best of both worlds - guarantee of correctness and performance.
-   "Just as Dafny will not discover properties of a method on its own, it will not know any but the most
    basic properties of a loop are preserved unless it is told via an invariant."
-   "The challenge in picking loop invariants is finding one that is preserved by the loop, but also that lets
    you prove what you need after the loop has executed."
-   "To find these invariants, we employ a common Dafny trick: working backwards from the postconditions. "
-   "Often a method is just a loop that, when it ends, makes the postcondition true by having a counter reach
    another number, often an argument or the length of an array or sequence."

https://rise4fun.com/Dafny/tutorial/Termination
https://rise4fun.com/Dafny/tutorial/Sets
https://rise4fun.com/Dafny/tutorial/Sequences
https://rise4fun.com/Dafny/tutorial/Collections
https://rise4fun.com/Dafny/tutorial/Lemmas

-   REREAD lemmas part is worth re-reading
    -   Also see: https://github.com/dafny-lang/dafny/blob/14c5be9/Test/dafny1/FindZero.dfy
    -   "So, the lemma is present solely for its effect on the verification of the program. You may think of
        lemmas as heavyweight assertions, in that they are only necessary to help the proof of the program
        along."
    -   "Recursive functions like this are prone to requiring lemmas."
    -   "A typical lemma might look like:"

```
lemma Lemma(...)
   ensures (desirable property)
{
   ...
}
```

-   "One way of proving the non-existence of something is to prove given any sequence of nodes that it cannot
    be a valid path. We can do this with, you guessed it, another lemma."
-   When writing lemmas, there's a lot of temporarily writing asserts/preconditions.
-   In order to prove something, punt it to another lemma. If the first thing passes, you then move onto the lemma.
-   Another technique - temporarily requires for a smaller problem, check your sub-lemma passes. This proves what
    sub-conditions to look for.

https://bitbucket.org/byucs329/byu-cs-329-lecture-notes/src/master/dafny/dafny-intro.md
