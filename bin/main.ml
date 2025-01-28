open Core
open Axis

let () =
  let yaml_string = In_channel.read_all "sample/config.yaml" in
  let parsed_config =
    match Yaml.of_string yaml_string with
    | Ok data -> Config.parse_yaml_data data
    | Error (`Msg msg) -> failwith msg
  in
  let scanner =
    match parsed_config with
    | First cfg -> Message.Scanner.init cfg.template.pattern
    | Second err ->
        Format.printf "%s | %s" (Config.cause_to_string err.cause) err.message;
        exit 1
  in
  let result = Message.Scanner.scan scanner in
  print_endline (Message.Scanner.show result)
