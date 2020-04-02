(** [Unix] helper module for {!Dns_client}.
    For more information see the {!Dns_client.Make} functor.
*)


(** A flow module based on blocking I/O on top of the Unix socket API.

    TODO: Implement the connect timeout.
*)
module Transport : Dns_client.S
  with type io_addr = Unix.inet_addr * int
   and type stack = unit
   and type +'a io = 'a

include module type of Dns_client.Make(Transport)
