# thx.tpl

[![Build Status](https://travis-ci.org/fponticelli/thx.tpl.svg)](https://travis-ci.org/fponticelli/thx.tpl)

Based on [erazor](https://github.com/ciscoheat/erazor), *thx.tpl* tries to get the syntax closer to *Haxe* string interpolation.

## basic usage

A template interpolates variables and control structures expressed as markup inside a string.

```haxe
var template = new Template("Hello $name");
trace(template.execute(['name' => 'Boris']));
// "Hello Boris"
```

The syntax for simple string interpolation is the same as the native Haxe syntax. If you have a complex expression you can put it into brackets to ensure that values are referred correctly.

```haxe
new Template("Hello ${person.name}");
```

*thx.tpl* is smarter and will interpolate correctly any expression that resembles a valid Haxe expression.

The following and the previous example are equivalent.

```haxe
new Template("Hello $person.name");
```

Again, use the curly braces if there is potential ambiguity.

```haxe
new Template("Hello ${name}.done.");
```

The same general rule applies to other expressions as well like function calls.

```haxe
new Template("Hello $person.displayLongName()");
```

When you work with *thx.tpl* you are always in one of two possible scopes: literal scope and expression scope. You generally start with the literal scope (``"Hello "`` in the above example) and you switch to expression scope using the `$`. Expression scopes can create sub-literal scopes like in the case of `if` or loop statements.

```haxe
new Template("$if(cond) { $(/* expression scope */)
  this is just a string literal $(/* literal scope */)
} else { $(/* expression scope */)
  and this is an alternative $(/* literal scope */)
} // expression scope")
```

Sometimes you need to define new variables or put some kind of computation that doesn't generate a direct output. To do so you embed your code in `$()`. It can be multiline.
This is the way we added comments in the snippet before.

```haxe
new Template("$(
  var numberOfEmails = person.contacts.emails.length;
)")
```

Inside code blocks you have to remember to close your statements with `;` as you would normally do in Haxe.

*thx.tpl* supports the following control statements:

```haxe
$if(condtion) { }
$if(condtion) { } else { }
$for(item in iterator) { }
$for(i in 0...10) { }
$while(condition) { }
```

To escape a `$` sign just repeat it twice.

```haxe
new Template("$${some}"); // will always generate `${some}`
```

## runtime templates

All the examples above are examples of runtime templates. The template string representation is parsed at runtime when the template is constructed and applied to an input using `template.execute(data)`.

Runtime templates use [hscript](https://github.com/HaxeFoundation/hscript) for the code logic.

Beside passing data to `execute` you can also setup utility functions and variables using the `addHelper` method of a `Template` instance.

```haxe
var template = new Template("$upperCaseFirst(name)");
template.addHelper(
  "upperCaseFirst",
  function(value)
    return values.substring(0, 1).toUpperCase() + values.substring(1))
```

## html templates

An instance of `HtmlTemplate` works almost exactly the same as an instance of `Template`. The only major difference is that values generated in `HtmlTemplate` are automatically sanitized to prevent `HTML` injection. If you still want to output the raw value you can use the helper function `raw` that is automatically available inside the template.

## install

```sh
haxelib install git https://github.com/fponticelli/thx.tpl.git src
```
