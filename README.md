## psq — Functional Priority Search Queues

%%VERSION%%

psq provides a functional priority search queue for OCaml. This structure
behaves both as a finite map, containing bindings `k -> p`, and a priority queue
over `p`. It provides efficient access along more than one axis: to any binding
by `k`, and to the binding(s) with the least `p`.

Typical applications are searches, schedulers and caches. If you ever scratched
your head because that A\* didn't look quite right, a PSQ is what you needed.

The implementation is backed by [priority search pennants][hinze].

psq is distributed under the ISC license.

[hinze]: https://www.cs.ox.ac.uk/ralf.hinze/publications/ICFP01.pdf

## Documentation

Interface files, or [online][doc].

[doc]: https://pqwy.github.io/psq/doc/psq/
