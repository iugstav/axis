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

type err_cause = NotFound | InvalidFormat
type config_error = { cause : err_cause; message : string }

val format_error : config_error -> string
val parse_yaml_data : string -> Yaml.value -> (t, config_error) Base.Either.t
