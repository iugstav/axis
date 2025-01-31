open Axis
open Core

(* lembrar de executar git commit -F - pra poder pegar o valor do pipe *)
let output s =
  let open Out_channel in
  let is_output = not (Core_unix.isatty Core_unix.stdout) in
  if is_output then (
    output_line stdout s;
    flush stdout)
  else print_endline s

let get_yaml_config templ yaml =
  match Yaml.of_string yaml with
  | Ok data -> Config.parse_yaml_data templ data
  | Error (`Msg msg) -> failwith msg

let run template_name user_message =
  let yaml =
    In_channel.read_all "sample/config.yaml" |> get_yaml_config template_name
  in
  let result =
    match yaml with
    | First config ->
        let open Message in
        let scanner = Scanner.init config.template.pattern |> Scanner.scan in
        Parser.init scanner.tokens config |> Parser.parse
    | Second err ->
        print_endline (Config.format_error err);
        exit 1
  in
  if List.is_empty result.errors then
    Message.Parser.build result user_message |> output
  else Message.Parser.parse_errors result.errors |> List.iter ~f:output

let cmd =
  let open Commands in
  let open Cmdliner in
  let info =
    Cmd.info "axis" ~version:"0.0.1"
      ~doc:
        "formats your commit message based on your templates in the \
         configuration file"
  in
  Cmd.v info Term.(const run $ templ_name $ user_message)

let () = exit (Cmdliner.Cmd.eval cmd)
