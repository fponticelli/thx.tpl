import utest.Runner;
import utest.ui.Report;

class TestAll {
  public static function addTests(runner : Runner) {
    runner.addCase(new thx.tpl.TestParser());
    runner.addCase(new thx.tpl.TestScriptBuilder());
    runner.addCase(new thx.tpl.TestTemplate());
  }

  public static function main() {
    var runner = new Runner();
    addTests(runner);
    Report.create(runner);
    runner.run();
  }
}
