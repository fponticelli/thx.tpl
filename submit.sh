rm thx.tpl.zip
zip -r thx.tpl.zip hxml src test extraParams.hxml haxelib.json LICENSE README.md -x "*/\.*"
haxelib submit thx.tpl.zip
