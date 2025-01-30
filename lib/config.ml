open Core
open Yaml

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

let cause_to_string = function
  | NotFound -> "Value not found"
  | InvalidFormat -> "Invalid format"

let format_error err =
  let cause = cause_to_string err.cause in
  Format.sprintf "%s ::: %s" cause err.message

let ( >>= ) t f = Option.bind t ~f
let get_string = function `String s -> Some s | _ -> None

let get_tuple = function
  | `O pairs ->
      Some
        (List.filter_map pairs ~f:(fun (k, v) ->
             get_string v |> Option.map ~f:(fun s -> (k, s))))
  | _ -> None

let find_prop prop_name v =
  match Util.find prop_name v with
  | Ok value ->
      Ok
        (Option.value value ~default:(`String "")
        |> get_string |> Option.value ~default:"")
  | Error (`Msg msg) -> Error { cause = NotFound; message = msg }

let get_template name = function
  | `O templ -> (
      let chosen_templ =
        List.find templ ~f:(fun el ->
            let templ_name, _ = el in
            String.equal templ_name name)
      in
      match chosen_templ with
      | Some t ->
          let ((name, info) : string * value) = t in
          let pattern = find_prop "pattern" info in
          let prefix = find_prop "prefix" info in
          let suffix = find_prop "suffix" info in
          let data_list = [ pattern; prefix; suffix ] in
          let templ =
            Result.all data_list
            |> Result.map ~f:(fun l ->
                   {
                     name;
                     pattern = List.nth_exn l 0;
                     prefix = List.nth_exn l 1;
                     suffix = List.nth_exn l 2;
                   })
          in
          templ
      | None ->
          Error
            {
              cause = NotFound;
              message = Format.sprintf "could not find %s" name;
            })
  | _ ->
      Error
        {
          cause = InvalidFormat;
          message =
            Format.sprintf
              "there is no template with name %s in the specified formats of \
               the application"
              name;
        }

let parse_yaml_data templ_name d =
  let variables =
    match Yaml.Util.find "variables" d with
    | Ok v -> v >>= get_tuple |> Option.value ~default:[]
    | Error (`Msg msg) -> failwith msg
  in
  let t =
    match Yaml.Util.find "templates" d with
    | Ok value -> (
        match value with
        | Some v -> get_template templ_name v
        | None -> failwith "não achou na template")
    | Error (`Msg msg) -> failwith msg
  in
  match t with
  | Ok template -> Either.First { variables; template }
  | Error e -> Either.Second e
