module Scanner : sig
  type token [@@deriving show]
  type error [@@deriving show]

  type t = {
    pattern : string;
    p_length : int;
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
    variables : (string * string) array;
    template : Config.template;
    tokens : Scanner.token array;
    values : pattern_values list;
    errors : error list;
    pos : int;
    actual : Scanner.token option;
  }
  [@@deriving show]

  val init : Scanner.token array -> Config.t -> t
  val parse : t -> t
  val build : t -> string -> string
  val parse_errors : error list -> string list
end
