import utest.UTest;

class TestAll {
  public static function main()
    UTest.run([
        new thx.tpl.TestParser(),
        new thx.tpl.TestScriptBuilder(),
        new thx.tpl.TestStaticResourceTemplate(),
        new thx.tpl.TestTemplate()
      ]);
}
