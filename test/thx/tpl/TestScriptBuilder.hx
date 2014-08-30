/**
 * @author Franco Ponticelli
 */

package thx.tpl;

import thx.tpl.Parser;
import thx.tpl.ScriptBuilder;

import utest.Assert;

class TestScriptBuilder {
  var builder : ScriptBuilder;

  public function new() { }

  public function setup()
    builder = new ScriptBuilder('b');

  public function test_If_print_and_literal_TBlocks_are_assembled_correctly() {
    var input = [TBlock.literal("Hello "), TBlock.printBlock("name")];

    assertScript([
      "b.add('Hello ');",
      "b.unsafeAdd(name);"
    ], builder.build(input));
  }

  public function test_If_keyword_TBlocks_are_assembled_correctly() {
    var input = [
      TBlock.codeBlock("if(a == 0) {"),
      TBlock.literal('Zero'),
      TBlock.codeBlock("} else if(a == 1 && b == 2) {"),
      TBlock.literal('One'),
      TBlock.codeBlock("} else {"),
      TBlock.literal('Above'),
      TBlock.codeBlock("}")
    ];

    assertScript([
      "if(a == 0) {",
      "b.add('Zero');",
      "} else if(a == 1 && b == 2) {",
      "b.add('One');",
      "} else {",
      "b.add('Above');",
      "}"
    ], builder.build(input));
  }

  public function test_If_for_TBlocks_are_assembled_correctly() {
    var input = [
      TBlock.codeBlock("for(u in users) {"),
      TBlock.printBlock('u.name'),
      TBlock.literal('<br>'),
      TBlock.codeBlock('}')
    ];

    assertScript([
      "for(u in users) {",
      "b.unsafeAdd(u.name);",
      "b.add('<br>');",
      "}"
    ], builder.build(input));
  }

  public function test_If_codeBlocks_are_assembled_correctly() {
    var input = [
      TBlock.codeBlock("a = 0; if(b == 2) {"),
      TBlock.literal('TEST'),
      TBlock.codeBlock('}')
    ];

    assertScript([
      "a = 0; if(b == 2) {",
      "b.add('TEST');",
      "}"
    ], builder.build(input));
  }

  private function assertScript(lines : Array<String>, expected : String)
    Assert.equals(expected, lines.join("\n"));
}