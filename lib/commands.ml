open Cmdliner

let templ_name =
  let doc = "name of the template" in
  Arg.(required & pos 1 (some string) None (info [] ~doc))

let user_message =
  let doc = "message to insert in the template" in
  Arg.(required & pos 2 (some string) None (info [] ~doc))
