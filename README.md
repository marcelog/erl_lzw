# erl_lzw
LZW implementation in Erlang, as explained in https://en.wikipedia.org/wiki/Lempel–Ziv–Welch

This is not optimized in any way, but was written just for fun.

# Example
```
1> {ok, Input} = file:read_file("./src/lzw.erl"),
2> {Output, Bits, Dict} = lzw:compress(Input),
3> Ori = lzw:uncompress(Output, Bits, Dict),
4> file:write_file("/tmp/original_file.txt", Ori).
```

## License
The source code is released under Apache 2 License.

Check [LICENSE](https://github.com/marcelog/erl_lzw/blob/master/LICENSE) file for more information.
