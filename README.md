# MasterBlaster
MasterBlaster is a strongly typed functional programming language.

It was founded to address a complaint that I made on the Elm discourse forum here:
https://discourse.elm-lang.org/t/why-couldnt-elm-or-an-elm-like-language-work-on-the-back-end/2766/23
(in case that server stops hosting that post, it has been duplicated in the todo.txt of this repository.)

For more information about the overarching goals of this language and it's design motivations, please do check the todo.txt file.

In short, after learning dozens of programming languages across as many architectures and environments over the past 36 years, I learned Elm and with it a contempt for any language that lacked some of Elm's philosophical features. But then with it, a contempt for some of Elm's OTHER philosophical features. So I eventually decided that the only solution was to make my own programming language. [With blackjack and hookers](https://www.youtube.com/watch?v=-94qrgxH35M).

As of 2020-12-29 it is still in its infancy. But, I like the name and it's uniqueness (nobody else appears to want to call their programming language MasterBlaster. Woot!) enough that now felt like a good stage to get it onto Github and stake my claim to this name for this kind of concept. :)

Currently it is a 3-stage compiler written in Perl, that can convert only the simplest examples of MasterBlaster's planned syntax into assembly code fit for gcc to assemble and link into elf64 binaries.

So far it's compiler error mechanism is decently user friendly, and a lot of early work has gone into higher order semantic parsing to help suppor the upcoming syntax limitations.
Actual program shape supported thus far is mostly "define and emit a constant literal number as an application error code and then exit."

Presuming I can wrangle the compiler into handling enough of the moving target of planned syntax that it can handle the task, I would next start writing the compiler itself in MasterBlaster and leave Perl behind as training wheels. That's when things can REALLY get cooking.

Wish me luck! 😄
