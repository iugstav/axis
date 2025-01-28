module Scanner : sig
  type t [@@deriving show]

  val init : string -> t
  val scan : t -> t
end
