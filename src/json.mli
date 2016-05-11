type t

val of_string : string -> t option
val to_string : t -> string

val string_member : string -> t -> string option
val b64_string_member : string -> t -> string option
val b64_z_member : string -> t -> Z.t option
val json_member : string -> t -> t option
