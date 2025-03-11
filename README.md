# Toggle-comments.nvim
Toggle-comments is a Neovim plugin to quickly comment and uncomment selected lines.

## 1 Toggle-comments show:
This video shows Toggle-comments demo:
![功能演示](https://raw.githubusercontent.com/Nanachilil/resources/main/toggle-comments.nvim/videos/demo.gif)


## 2 Quickly use
`lazyvim`:
``` lua
return {
    "nanachilil/toggle-comments.nvim",
    opts = {
		symbol = "// ",
		pattern = "^%s*// ",     
    }
}

```
Then, we can use `Control + /` to toggle comments.
