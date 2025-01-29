module Scanner : sig
  type token [@@deriving show]
  type error [@@deriving show]

  type t = {
    pattern : string;
    tokens : token list;
    errors : error list;
    ch : char option;
    pos : int;
  }
  [@@deriving show]

  val init : string -> t
  val scan : t -> t
end

module Parser : sig
  type error_position [@@deriving show]
  type error [@@deriving show]
  type pattern_values [@@deriving show]

  type t = {
    variables : (string * string) list;
    template : Config.template;
    tokens : Scanner.token list;
    values : pattern_values list;
    errors : error list;
    pos : int;
    actual : Scanner.token option;
  }
  [@@deriving show]

  val init : Scanner.token list -> Config.t -> t
  val parse : t -> t
end
