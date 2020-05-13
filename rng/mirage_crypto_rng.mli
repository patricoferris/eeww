(** {1 Randomness} *)

(** Secure random number generation.

    There are several parts of this module:

    {ul
    {- The {{!Generator}signature} of generator modules, together with a
       facility to convert such modules into actual {{!g}generators}, and
       functions that operate on this representation.}
    {- A global generator instance, which needs to be initialized by calling
       {!set_default_generator}.}}
*)

(** {1 Usage notes} *)

(** {b TL;DR} Don't forget to seed; don't maintain your own [g].

    The RNGs here are merely the deterministic part of a full random number
    generation suite. For proper operation, they need to be seeded with a
    high-quality entropy source.

    Suitable generators are provided by sub-libraries
    {{!Mirage_crypto_rng_unix}mirage-crypto-rng.unix}
    and {{!Mirage_crypto_entropy}mirage-crypto-entropy} (for MirageOS).
    Although this module exposes a more fine-grained interface, allowing manual
    seeding of generators, this is intended either for implementing
    entropy-harvesting modules, or very specialized purposes. Users of this
    library should almost certainly use one of the above entropy libraries, and
    avoid manually managing the generator seeding.

    Similarly, although it is possible to swap the default generator and gain
    control over the random stream, this is also intended for specialized
    applications such as testing or similar scenarios where the RNG needs to be
    fully deterministic, or as a component of deterministic algorithms which
    internally rely on pseudorandom streams.

    In the general case, users should not maintain their local instances of
    {{!g}g}. All of the generators in a process have to compete for entropy, and
    it is likely that the overall result will have lower effective
    unpredictability.

    The recommended way to use these functions is either to accept an optional
    generator and pass it down, or to ignore the generator altogether, as
    illustrated in the {{!rng_examples}examples}.
*)

type bits = int

(** {1 Interface} *)

type g
(** A generator (PRNG) with its state. *)

exception Unseeded_generator
(** Thrown when using an uninitialized {{!g}generator}. *)

exception No_default_generator
(** Thrown when {!set_generator} has not been called. *)

exception Default_generator_already_set
(** Thrown when {!set_generator} is called a second time. *)

(** A single PRNG algorithm. *)
module type Generator = sig

  type g
  (** State type for this generator. *)

  val block : int
  (** Internally, this generator's {{!generate}generate} always produces
      [k * block] bytes. *)

  val create : ?time:(unit -> int64) -> unit -> g
  (** Create a new, unseeded {{!g}g}. *)

  val generate : g:g -> int -> Cstruct.t
  (** [generate ~g n] produces [n] uniformly distributed random bytes,
      updating the state of [g]. *)

  val reseed : g:g -> Cstruct.t -> unit
  (** [reseed ~g bytes] directly updates [g]. Its new state depends both on
      [bytes] and the previous state.

      A generator is seded after a single application of [reseed]. *)

  val accumulate : g:g -> source:int -> [`Acc of Cstruct.t -> unit]
  (** [accumulate ~g] is a closure suitable for incrementally feeding
      small amounts of environmentally sourced entropy into [g].

      Its operation should be fast enough for repeated calling from e.g.
      event loops. Systems with several distinct, stable entropy sources
      should use stable [source] to distinguish their sources. *)

  val seeded : g:g -> bool
  (** [seeded ~g] is [true] iff operations won't throw
      {{!Unseeded_generator}Unseeded_generator}. *)

  val pools : int
  (** [pools] is the amount of pools if any. *)
end

type 'a generator = (module Generator with type g = 'a)

(** Ready-to-use RNG algorithms. *)

(** {b Fortuna}, a CSPRNG {{: https://www.schneier.com/fortuna.html} proposed}
    by Schneier. *)
module Fortuna : Generator

(** {b HMAC_DRBG}: A NIST-specified RNG based on HMAC construction over the
    provided hash. *)
module Hmac_drbg (H : Mirage_crypto.Hash.S) : Generator

val create : ?g:'a -> ?seed:Cstruct.t -> ?strict:bool ->
  ?time:(unit -> int64) -> (module Generator with type g = 'a) -> g
(** [create ~g ~seed ~strict ~time module] uses a module conforming to the
    {{!Generator}Generator} signature to instantiate the generic generator
    {{!g}g}.

    [g] is the state to use, otherwise a fresh one is created.

    [seed] can be provided to immediately reseed the generator with.

    [strict] puts the generator into a more standards-conformant, but slighty
    slower mode. Useful if the outputs need to match published test-vectors.

    [time] is used to limit the amount of reseedings. Fortuna uses at most once
    every second. *)

val default_generator : unit -> g
(** [default_generator ()] is the default generator. Functions in this module
    use this generator when not explicitly supplied one.

    @raise No_default_generator if {!set_generator} has not been called. *)

val set_default_generator : g -> unit
(** [set_default_generator g] sets the default generator to [g]. This function
    must be called once.

    @raise Default_generator_already_set if called a second time. *)

val generate : ?g:g -> int -> Cstruct.t
(** Invoke {{!Generator.generate}generate} on [g] or
    {{!generator}default generator}. *)

val block : g option -> int
(** {{!Generator.block}Block} size of [g] or
    {{!generator}default generator}. *)

(**/**)

(* The following functions expose the seeding interface. They are meant to
 * connect the RNG with entropy-providing libraries and subject to change.
 * Client applications should not use them directly. *)

val reseed     : ?g:g -> Cstruct.t -> unit
val accumulate : g option -> source:int -> [`Acc of Cstruct.t -> unit]
val seeded     : g option -> bool
val pools      : g option -> int
val strict : g option -> bool
(**/**)


(** {1:rng_examples Examples}

    Generating a random 13-byte {!Cstruct.t}:
{[let cs = Rng.generate 13]}

    Generating a list of {!Cstruct.t}, passing down an optional {{!g}generator}:
{[let rec f1 ?g ~n i =
  if i < 1 then [] else Rng.generate ?g n :: f1 ?g ~n (i - 1)]}

    Generating a [Z.t] smaller than [10]:
{[let f2 ?g () = Mirage_crypto_pk.Z_extra.gen ?g Z.(~$10)]}

    Creating a local Fortuna instance and using it as a key-derivation function:
{[let f3 secret =
  let g = Rng.(create ~seed:secret (module Generators.Fortuna)) in
  Rng.generate ~g 32]}
*)
