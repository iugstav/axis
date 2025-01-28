type template = {
  name : string;
  (*scope : string option;*)
  pattern : string;
  prefix : string;
  suffix : string;
}
[@@deriving show]

type t = { variables : (string * string) list; template : template }
[@@deriving show]

type err_cause = NotFound | ForbbidenName | InvalidFormat | Unindentified
type parser_error = { cause : err_cause; message : string }

val cause_to_string : err_cause -> string
val parse_yaml_data : Yaml.value -> (t, parser_error) Base.Either.t
