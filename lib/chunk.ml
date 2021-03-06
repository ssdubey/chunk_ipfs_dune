

module Simple =
  struct

    (* Chunk representation

       The binary representation of p is specified in the IPLD
       specification.

         https://github.com/ipld/specs/tree/master/ipld


       IPFS NOTES

       echo "���C" | ipfs dag put --input-enc raw
       zdpuAxKCBsAKQpEw456S49oVDkWJ9PZa44KGRfVBWHiXN3UH8 

       ipfs block get zdpuAxKCBsAKQpEw456S49oVDkWJ9PZa44KGRfVBWHiXN3UH8 

     *)

    type cbor = CBOR.Simple.t

    type hash = string 
                  
    type weight = int
                    
    type item = cbor
                  
    type chunk = cbor
                   
    type chunk_pointer = hash
                           
    let ipfs_path = "/usr/local/bin/ipfs"  (*or check with /usr/local/bin//ipfs*)
        
    let hash_len = 49 (* nb chars to represent sha256 hash *)

    let ipfs_put_cbor : cbor -> hash = fun c ->
      let b = CBOR.Simple.encode c in
      let result = ref "" in
      let (fd_in1, fd_out1) = Unix.pipe() in
      let (fd_in2, fd_out2) = Unix.pipe() in
      (match Unix.fork() with
       | 0 -> (
          Unix.dup2 fd_in1 Unix.stdin;
          Unix.dup2 fd_out2 Unix.stdout;
          Unix.close fd_in1;
          Unix.close fd_out1;
          Unix.close fd_out2;
          Unix.handle_unix_error Unix.execv ipfs_path ([| ipfs_path; "dag"; "put"; "--input-enc"; "raw"; |]);
          ())
       | _ -> (
          let out_ch = Unix.out_channel_of_descr fd_out1 in
          output_bytes out_ch b;
          close_out out_ch;
          (match Unix.wait () with
           | (pid, Unix.WEXITED retcode) -> ()
           | _ -> failwith "ipfs put");
          let buf = Bytes.create hash_len in
          let in_ch = Unix.in_channel_of_descr fd_in2 in
          input in_ch buf 0 hash_len;
          close_in in_ch;
          result := Bytes.to_string buf;
          Unix.close fd_in1;
          ()));
      ! result

        (*
    let ipfs_put_cbor_to_file : cbor -> hash = fun c ->
      let b = CBOR.Simple.encode c in
      let result = ref "" in
      let (fd_in1, fd_out1) = Unix.pipe() in
      let (fd_in2, fd_out2) = Unix.pipe() in
      (match Unix.fork() with
       | 0 -> (
          Unix.dup2 fd_in1 Unix.stdin;
          Unix.dup2 fd_out2 Unix.stdout;
          Unix.close fd_in1;
          Unix.close fd_out1;
          Unix.close fd_out2;
          let foo_path = "/Users/rainey/Work/chunkedseq-ipfs/foo.sh" in
          Unix.handle_unix_error Unix.execv foo_path ([| foo_path |]);
          ())
       | _ -> (
          let out_ch = Unix.out_channel_of_descr fd_out1 in
          output_bytes out_ch b;
          close_out out_ch;
          (match Unix.wait () with
           | (pid, Unix.WEXITED retcode) -> ()
           | _ -> failwith "ipfs put");
          let buf = Bytes.create hash_len in
          let in_ch = Unix.in_channel_of_descr fd_in2 in
          input in_ch buf 0 hash_len;
          close_in in_ch;
          result := Bytes.to_string buf;
          Unix.close fd_in1;
          ()));
      ! result
         *)
        
    let ipfs_get_nb_bytes_of_cbor : hash -> int = fun h ->
      let result = ref 0 in
      let (fd_in, fd_out) = Unix.pipe() in
      (match Unix.fork() with
       | 0 -> (
          Unix.dup2 fd_out Unix.stdout;
          Unix.close fd_out;
          Unix.handle_unix_error Unix.execv ipfs_path ([| ipfs_path; "block"; "stat"; h; |]);
          ())
       | _ -> (
         (match Unix.wait () with
           | (pid, Unix.WEXITED retcode) -> ()
           | _ -> failwith "ipfs get");
         let in_ch = Unix.in_channel_of_descr fd_in in
         input_line in_ch; (* discard first line *)
         let l = input_line in_ch in
         let spos = String.length "Size: " in
         let v = String.sub l spos (String.length l - spos) in
         let n = int_of_string v in
         close_in in_ch;
         result := n;
         ()));
      ! result

    let ipfs_get_cbor : hash -> cbor = fun h ->
      let result = ref `Null in
      let nb_bytes = ipfs_get_nb_bytes_of_cbor h in
      let (fd_in, fd_out) = Unix.pipe() in
      (match Unix.fork() with
       | 0 -> (
          Unix.dup2 fd_out Unix.stdout;
          Unix.close fd_out;
          Unix.handle_unix_error Unix.execv ipfs_path ([| ipfs_path; "block"; "get"; h; |]);
          ())
       | _ -> (
         (match Unix.wait () with
           | (pid, Unix.WEXITED retcode) -> ()
           | _ -> failwith "ipfs get");
         let buf = Bytes.create nb_bytes in
         let in_ch = Unix.in_channel_of_descr fd_in in
         input in_ch buf 0 nb_bytes;
         close_in in_ch;
         result := CBOR.Simple.decode buf;
         ()));
      ! result

    let weight_key = "wt"

    let contents_key = "ct"

    let contents_of_chunk c =
      match c with
      | `Map [ (`Text weight_key, `Int w);      (`Text contents_key, `Array xs); ] ->
          (w, xs)
      | `Map [ (`Text contents_key, `Array xs); (`Text weight_key, `Int w); ] ->
          (w, xs)
      | _ -> assert false

    let mk_chunk w xs =
      `Map [(`Text weight_key, `Int w); (`Text contents_key, `Array xs)]

    let weight_of_chunk : chunk_pointer -> weight = fun p ->
      (* later: see if it's possible to load just the weight via ipfs *)
      let c = ipfs_get_cbor p in
      let (w, _) = contents_of_chunk c in
      w

    let mk_item x =
      `Int x

    let mk_link h =
      `Link h
        
    let weight_of_item x =
      match x with
      | `Int _ ->
         1
      | `Link l ->
         let _ = Printf.printf "l=%s\n" l in
         weight_of_chunk l
      | _ ->
         assert false
            
    let create : chunk =
      mk_chunk 0 []

    let push_back c x =
      let (w, xs) = contents_of_chunk c in
      let w' = w + weight_of_item x in
      let xs' = List.append xs [x] in
      mk_chunk w' xs'
        
    let push_front c x =
      let (w, xs) = contents_of_chunk c in
      let w' = w + weight_of_item x in
      let xs' = x :: xs in
      mk_chunk w' xs'
        
    let pop_back c =
      let (w, xs) = contents_of_chunk c in
      let sx = List.rev xs in
      match sx with
      | x :: sx' ->
          let w' = w - weight_of_item x in
          let xs' = List.rev sx' in
          (mk_chunk w' xs', x)
      | _ -> assert false
            
    let pop_front c =
      let (w, xs) = contents_of_chunk c in
      match xs with
      | x :: xs' ->
          let w' = w - weight_of_item x in
          (mk_chunk w' xs', x)
      | _ -> assert false

    let concat (c1, c2) =
      let (w1, xs1) = contents_of_chunk c1 in
      let (w2, xs2) = contents_of_chunk c2 in
      let w = w1 + w2 in
      let xs = List.append xs1 xs2 in
      mk_chunk w xs

    let sigma xs =
      let ws = List.map weight_of_item xs in
      List.fold_left (fun x y -> x + y) 0 ws
               
    let split (c, i) =
      let rec f (sx, xs, w) =
        match xs with
        | x :: xs' ->
            let w' = w + (weight_of_item x) in
            if w' > i then
              (List.rev sx, x, xs')
            else
              f (x :: sx, xs', w')
        | [] ->
            failwith "Chunk.split: bogus input"
      in
      let (_, xs) = contents_of_chunk c in
      let (xs1, x, xs2) = f ([], xs, 0) in
      let c1 = mk_chunk (sigma xs1) xs1 in
      let c2 = mk_chunk (sigma xs2) xs2 in
      (c1, x, c2)

  end


