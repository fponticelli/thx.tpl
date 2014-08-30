/**
 * $author Franco Ponticelli
 */

package thx.tpl;

import thx.tpl.ParserError;
import thx.tpl.Parser;
import utest.Assert;

class TestParser {
  var parser : Parser;

  public function new(){}

  public function setup()
    parser = new Parser();

  public function test_If_literals_are_parsed_correctly() {
    // Plain text
    var output = parser.parse("Hello there\nHow are you?");
    Assert.same([literal("Hello there\nHow are you?")], output);

    // Javascript in the template
    output = parser.parse("<script>if(document.getElementById(\"test\")) { alert(\"ok\"); }</script>");
    Assert.same([literal("<script>if(document.getElementById(\"test\")) { alert(\"ok\"); }</script>")], output);
  }

  public function test_If_escaped_blocks_are_parsed_correctly() {
    var output = parser.parse("normal$$email.com");
    Assert.same([literal("normal$email.com")], output);

    output = parser.parse("AtTheEnd$");
    Assert.same([literal("AtTheEnd$")], output);

    output = parser.parse("more$$than$$one");
    Assert.same([literal("more$than$one")], output);

    output = parser.parse("$$$${hello}");
    Assert.same([literal("$${hello}")], output);
  }

  public function test_If_printblocks_are_parsed_correctly() {
    var output : Array<TBlock>;

    // Simple substitution
    output = parser.parse("Hello $name");
    Assert.same([literal("Hello "), printBlock("name")], output);

    // String substitution
    output = parser.parse("Hello$(name)abc");
    Assert.same([literal("Hello"), codeBlock("name"), literal("abc")], output);

    // String substitution
    output = parser.parse("Hello${name}abc");
    Assert.same([literal("Hello"), printBlock("name"), literal("abc")], output);

    output = parser.parse("Hello ${\"Boris\"}");
    Assert.same([literal("Hello "), printBlock('"Boris"')], output);

    // String substitution with escaped quotation marks
    output = parser.parse('Hello $'+'{a + "A \\" string."}');
    Assert.same([literal("Hello "), printBlock('a + "A \\" string."')], output);

    output = parser.parse("Hello ${a + 'A \\' string.'}");
    Assert.same([literal("Hello "), printBlock("a + 'A \\' string.'")], output);

    output = parser.parse("${\"'Mixing'\"}");
    Assert.same([printBlock("\"'Mixing'\"")], output);

    // Braces around var
    output = parser.parse("Hello {$name}");
    Assert.same([literal("Hello {"), printBlock("name"), literal("}")], output);

    // Concatenated vars with space between start/end of block
    output = parser.parse("${ user.firstname + \" \" + user.lastname }");
    Assert.same([printBlock("user.firstname + \" \" + user.lastname")], output);
  }

  public function test_If_codeblocks_are_parsed_correctly() {
    // Single codeblock
    var output = parser.parse("Test: $(a = 0; Lib.print(\"Evil Bracke}\"); )");
    Assert.same([
      literal("Test: "),
      codeBlock("a = 0; Lib.print(\"Evil Bracke}\");")
    ], output);

    var output = parser.parse("Test: $(a = 0; Lib.print(\"Evil Bracke)\"); )");
    Assert.same([
      literal("Test: "),
      codeBlock("a = 0; Lib.print(\"Evil Bracke)\");")
    ], output);

    // Nested codeblock
    var output = parser.parse("$( a = 0; if(b == 2) { Lib.print(\"Ok\"); })");
    Assert.same([
      codeBlock("a = 0; if(b == 2) { Lib.print(\"Ok\"); }")
    ], output);

    // $ in codeblock
    var output = parser.parse("$( a = 0; if(b == 2) { Lib.print(\"a$b\"); })");
    Assert.same([
      codeBlock("a = 0; if(b == 2) { Lib.print(\"a$b\"); }")
    ], output);
  }

  public function test_More_complicated_variables() {
    var output : Array<TBlock>;

    output = parser.parse("$custom(0, 10, \"test(\")");
    Assert.same([printBlock("custom(0, 10, \"test(\")")], output);

    output = parser.parse("$test[a+1]");
    Assert.same([printBlock("test[a+1]")], output);

    output = parser.parse("$test.users[user.id]");
    Assert.same([printBlock("test.users[user.id]")], output);

    output = parser.parse("$test.user.id");
    Assert.same([printBlock("test.user.id")], output);

    output = parser.parse("$getFunction()()");
    Assert.same([printBlock("getFunction()()")], output);
  }

  public function test_If_keyword_blocks_are_parsed_correctly() {
    // if
    var output = parser.parse("Test: $if(a == 0) { Zero }");
    Assert.same([literal("Test: "), codeBlock("if(a == 0) {"), literal(" Zero "), codeBlock("}")], output);

    // nested if
    var output = parser.parse("$if(a) { $if(b) { Ok }}");
    Assert.same([
      codeBlock("if(a) {"),
      literal(" "),
      codeBlock("if(b) {"),
      literal(" Ok "),
      codeBlock("}"),
      codeBlock("}")
    ], output);

    // if/else if/else spaced out
    var output = parser.parse("$if (a == 0) { Zero } else if (a == 1 && b == 2) { One } else { Above }");
    Assert.same([
      codeBlock("if (a == 0) {"),
      literal(" Zero "),
      codeBlock("} else if (a == 1 && b == 2) {"),
      literal(" One "),
      codeBlock("} else {"),
      literal(" Above "),
      codeBlock("}")
    ], output);

    // if/else if/else with some space between braces
    output = parser.parse("$if (a == 0) { Zero }else if(a == 1 && b == 2) {One} else{ Above }");
    Assert.same([
      codeBlock("if (a == 0) {"),
      literal(" Zero "),
      codeBlock("}else if(a == 1 && b == 2) {"),
      literal("One"),
      codeBlock("} else{"),
      literal(" Above "),
      codeBlock("}")
    ], output);

    // if/else if/else with no space between braces
    output = parser.parse("$if(a == 0){Zero}else if(a == 1 && b == 2){One}else{Above}");
    Assert.same([
      codeBlock("if(a == 0){"),
      literal("Zero"),
      codeBlock("}else if(a == 1 && b == 2){"),
      literal("One"),
      codeBlock("}else{"),
      literal("Above"),
      codeBlock("}")
    ], output);

    // for
    output = parser.parse("$for (u in users) { $u.name<br> }");
    Assert.same([
      codeBlock("for (u in users) {"),
      literal(" "),
      printBlock("u.name"),
      literal("<br> "),
      codeBlock("}")
    ], output);

    // for IntIterator
    output = parser.parse("$for (i in 0...3) { $i<br> }");
    Assert.same([
      codeBlock("for (i in 0...3) {"),
      literal(" "),
      printBlock("i"),
      literal("<br> "),
      codeBlock("}")
    ], output);

    // while
    output = parser.parse("$while( a > 0 ) { $(a--;) }");
    Assert.same([
      codeBlock("while( a > 0 ) {"),
      literal(" "),
      codeBlock("a--;"),
      literal(" "),
      codeBlock("}")
    ], output);
  }

  public function test_If_parsing_exceptions_are_thrown() {
    var self = this;

    // Unclosed tags
    Assert.raises(function() {
      self.parser.parse("$if (incompleted == true)");
    }, ParserError);

    Assert.raises(function() {
      self.parser.parse("${unclosed{{");
    }, ParserError);

    Assert.raises(function() {
      self.parser.parse("$if(a == \"Oops)}");
    }, ParserError);

    //non-paired brackets

    Assert.raises(function() {
      self.parser.parse("$if(true){{}");
    }, ParserError);

    Assert.raises(function() {
      self.parser.parse("$if(true){}}");
    }, ParserError);
  }

  public function test_If_paired_brackets_are_parsed_correctly() {
    var output;

    output = parser.parse("$if(true){ {} }");
    Assert.same([
      codeBlock("if(true){"),
      literal(" {} "),
      codeBlock("}")
    ], output);

    output = parser.parse("$for(i in 0...3){ {{}{{}}} }");
    Assert.same([
      codeBlock("for(i in 0...3){"),
      literal(" {{}{{}}} "),
      codeBlock("}")
    ], output);
  }
}