(*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)
(** A Context is used to represent every API invocation. It may be extended
    to include extra data without changing all the autogenerated signatures *)
type t 

type origin =
  | Http of Http.request * Unix.file_descr
  | Internal

(** {6 Constructors} *)

(** [initial] is the initial context. *)
val initial : t

(** [make ~__context ~subtask_of ~database ~session_id ~task_in_database ~task_description ~origin name] creates a new context. 
    [__context] is the calling context,
	[quiet] silences "task created" log messages,
    [subtask_of] is a reference to the parent task, 
    [session_id] is the current session id,
	[database] is the database to use in future Db.* operations
    [task_in_database] indicates if the task needs to be stored the task in the database, 
    [task_descrpition] is the description of the task,
    [task_name] is the task name of the created context. *)
val make :
  ?__context:t ->
  ?quiet:bool ->
  ?subtask_of:API.ref_task ->
  ?session_id:API.ref_session ->
  ?database:Db_ref.t ->
  ?task_in_database:bool ->
  ?task_description:string -> ?origin:origin -> string -> t

val from_forwarded_task :
  ?__context:t ->
  ?session_id:API.ref_session ->
  ?origin:origin -> API.ref_task -> t
  
(** {6 Accessors} *)

(** [session_of_t __context] returns the session id stored in [__context]. In case there is no session id in this
    context, it fails with [Failure "Could not find a session_id"]. *)
val get_session_id : t -> API.ref_session

(** [get_task_id __context] returns the task id stored in [__context]. Such a task can be either a task stored in 
    database or a tempory task (also called dummy). *)
val get_task_id : t -> API.ref_task

val forwarded_task : t -> bool

val string_of_task : t -> string 

val get_task_id_string_name : t -> string * string

(** [task_in_database __context] indicates if [get_task_id __context] corresponds to a task stored in database or
    to a dummy task. *)
val task_in_database : t -> bool

(** [get_name __context] returns the name of the task stored in [__context]. This name is useful for dummy tasks,
    as they do not have name associated in database. *)
val get_task_name : t -> string

(** [get_origin __context] returns a string containing the origin of [__context]. *)
val get_origin : t -> string

(** [string_of __context] returns a string representing the context. *)
val string_of : t -> string

(** [database_of __context] returns a database handle, which can be used by Db.* *)
val database_of : t -> Db_ref.t

(** {6 Destructors} *)

val destroy : t -> unit

(** {6 Auxiliary functions } *)

(** [is_unix_socket fd] *)
val is_unix_socket : Unix.file_descr -> bool

(** [is_unencrypted fd] returns true if the calling connection is not encrypted *)
val is_unencrypted : Unix.file_descr -> bool

(** [preauth ~__context] *)
val preauth : __context:t -> bool

val trackid_of_session: ?with_brackets:bool -> ?prefix:string -> API.ref_session option -> string
val trackid : ?with_brackets:bool -> ?prefix:string -> t -> string

(** {6 Functions which help resolving cyclic dependencies} *)

val __get_task_name : (__context:t -> API.ref_task -> string) ref
val __destroy_task  : (__context:t -> API.ref_task -> unit  ) ref
val __make_task :
  (__context:t -> ?description:string ->
   ?session_id:API.ref_session ->
   ?subtask_of:API.ref_task -> string -> API.ref_task * API.ref_task Uuid.t)
  ref
val __string_of_task : (string -> API.ref_task -> string) ref
